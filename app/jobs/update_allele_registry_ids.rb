require 'rbconfig'

class UpdateAlleleRegistryIds < ActiveJob::Base
  def perform(recurring = true)
    begin
      for v in Variant.where(allele_registry_id: nil) do
        allele_registry_id = get_allele_registry_id(v)
        v.allele_registry_id = allele_registry_id
        v.save
      end
      for v in Variant.where.not(allele_registry_id: nil) do
        allele_registry_id = get_allele_registry_id(v)
        add_allele_registry_link(allele_registry_id)
      end
    ensure
      reschedule if recurring
    end
  end

  def add_allele_registry_link(allele_registry_id)
    system("#{ruby_executable} #{script_path} put \"reg.test.genome.network/allele/#{allele_registry_id}/externalSource/civic\" \"p1=#{allele_registry_id}\" #{allele_registry_username} #{allele_registry_password}")
  end

  def ruby_executable
    RbConfig.ruby
  end

  def script_path
    File.join(Rails.root, 'misc_scripts', 'add_allele_registry_link.rb')
  end

  def reschedule
    self.class.set(wait_until: next_day).perform_later
  end

  def next_day
    Date.tomorrow
      .midnight
  end

  def get_allele_registry_id(variant)
    response = response(variant)
    JSON.parse(response)['@id'].split('/')[-1] rescue nil
  end

  def response(variant)
    if hgvs = HgvsExpression.allele_registry_hgvs(variant)
      make_request(hgvs)
    else
      {}
    end
  end

  private
  def make_request(hgvs)
    Scrapers::Util.make_get_request(allele_registry_url(hgvs))
  rescue StandardError
    {}
  end

  def allele_registry_url(coordinate_string)
    URI.encode("http://reg.genome.network/allele?hgvs=#{coordinate_string}")
  end

  def allele_registry_username
    ENV['ALLELE_REGISTRY_USERNAME'] || Rails.application.secrets.allele_registry_username
  end

  def allele_registry_password
    ENV['ALLELE_REGISTRY_PASSWORD'] || Rails.application.secrets.allele_registry_password
  end
end
