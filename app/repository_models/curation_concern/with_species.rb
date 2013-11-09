module CurationConcern
  module WithSpecies
    extend ActiveSupport::Concern

    included do
      delegate_to :descMetadata, [:species]

      #before_save :copy_species_from_subject
    end

    def copy_species_from_subject
      puts "copy from subjects"
      subjects=self.subject
      species=self.species || []
      unless subjects.blank?
        subjects.each do |sub|
          #TODO make sure subject is not part of species
          species<<sub unless NcbiSpeciesTerms.find_all_by_term(sub).blank?
        end
      end
      puts "Asset: #{self.pid}, Species to copy:#{species}"
      self.species=species.to_a.uniq
    end

  end
end
