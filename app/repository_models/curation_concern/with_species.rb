module CurationConcern
  module WithSpecies
    extend ActiveSupport::Concern

    included do
      delegate_to :descMetadata, [:species]
    end

    #This method will be used onetime species copy
   def assign_species_from_subject
      subjects=self.subject
      species=self.species || []
      unless subjects.blank?
        subject_terms = []
        subjects.each { |s| subject_terms << s }
        sp_terms = NcbiSpeciesTerm.get_species_term(subject_terms)
        if sp_terms.length > 0
          sp_terms.each do |s|
            species << s.term
          end
          self.species = species.to_a.uniq
        end
      end
    end

    #Include species from subject as well to species hierarchy
    def get_hierarchical_faceting_on_species(species=self.species)
      all_trees=[]
      speices_to_solrize=species.to_a+(self.subject || [])
      ncbi_species= NcbiSpeciesTerm.get_species_term(speices_to_solrize.uniq)
      ncbi_species.each do |specie|
        all_trees<<specie.get_solr_hierarchy_from_tree.flatten
      end
      return all_trees.flatten
    end

  end
end
