module CurationConcern
  module WithCitationFiles
    extend ActiveSupport::Concern

    included do
      has_many :generic_files, property: :is_part_of, class_name: 'CitationFile'

      after_destroy :after_destroy_cleanup
    end

    def after_destroy_cleanup
      puts "cleaning up generic files now"
      generic_files.each(&:destroy)
    end

  end
end
