module CurationConcern
  module WithExternalFiles
    extend ActiveSupport::Concern

    included do
      has_metadata name: 'external_file', type: UrlDatastream

      #delegate_to :external_file, [:file_location]
    end

    def file_location
      self.datastreams["external_file"].content
    end

    def file_location=(value)
      self.datastreams["external_file"].content=value
    end

  end
end
