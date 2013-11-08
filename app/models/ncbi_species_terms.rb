class NcbiSpeciesTerms < ActiveRecord::Base
  self.table_name = 'species_taxon_entries'
  
  attr_accessible :species_taxon_id, :subject_description,:term, :term_synonyms,  :term_type,
                  :full_tree_id,  :facet_tree_id, :facet_tree_term

  serialize :term_synonyms

  self.primary_key = 'species_taxon_id'

end