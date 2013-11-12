module CurationConcern
  module WithSpecies
    extend ActiveSupport::Concern

    included do
      delegate_to :descMetadata, [:species]
      before_save :assign_species_from_subject
    end

    def assign_species_from_subject
      subjects=self.subject
      species=self.species || []
      unless subjects.blank?
        subjects.each do |sub|
          #TODO make sure subject is not part of species
          species<<sub unless NcbiSpeciesTerm.get_species_term(sub).blank?
        end
      end
      self.species=species.to_a.uniq
    end

    def get_hierarchical_faceting_on_species(species=self.species)
      all_trees=[]
      species.each do |specie|
        ncbi_species= NcbiSpeciesTerm.get_species_term(specie)
        ncbi_species.each do |specie|
          all_trees<<specie.get_solr_hierarchy_from_tree.flatten
        end
      end
      return all_trees.flatten
    end

  end
end
