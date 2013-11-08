class NcbiSpeciesTerms < ActiveRecord::Base
  self.table_name = 'species_taxon_entries'

  attr_accessible :species_taxon_id, :subject_description,:term, :term_synonyms,  :term_type,
                  :full_tree_id,  :facet_tree_id, :facet_tree_term

  serialize :term_synonyms

  self.primary_key = 'species_taxon_id'


  def self.load_from_tree_file(tree_filename)
    entries = []
    File.open(tree_filename) do |f|
      f.each do |line|
        fields = line.strip.split('|')
        entries << NcbiSpeciesTerms.new(species_taxon_id: fields[0],
                                        term: fields[1],
                                        term_type: fields[2],
                                        full_tree_id: fields[3]
                                       )
      end
    end
    NcbiSpeciesTerms.import entries
  end

end
