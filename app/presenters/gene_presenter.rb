class GenePresenter
  def initialize(gene)
    @gene = gene
  end

  def as_json(options = {})
    {
      id: @gene.id,
      entrez_name: @gene.name,
      entrez_id: @gene.entrez_id,
      description: @gene.description,
      clinical_description: @gene.clinical_description,
      variants: @gene.variants.map(&:name),
      variant_groups: @gene.variant_groups.map(&:name),
    }.merge(errors)
  end

  private
  def errors
    if @gene.errors.any?
      {
        errors: @gene.errors.to_hash
      }
    else
      {}
    end
  end
end