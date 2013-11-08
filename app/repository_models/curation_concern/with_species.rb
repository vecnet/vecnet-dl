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
      species=[]
      unless subjects.blank?
        subjects.each do |sub|
          species<<sub unless SubjectMeshEntry.find_all_by_term(sub).blank?
        end
      end
      puts "Species to copy:#{species}"
      self.species=species
    end

  end
end
