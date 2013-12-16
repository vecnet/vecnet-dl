module CurationConcern
  module WithExternalFiles
    extend ActiveSupport::Concern

    included do
      has_metadata name: 'external_file', type: UrlDatastream
        attr_accessor :linked_resource_url
   end

    def absolute_location
      external_file.file_location
    end

    def absolute_location=(value)
      external_file.file_location = value
    end

  end
end
