module CurationConcern
  module WithExternalFiles
    extend ActiveSupport::Concern

    included do
      has_metadata name: 'external_file', type: UrlDatastream

      attr_accessor :linked_resource_url

      #delegate_to :external_file, [:file_location]
    end
    #This assusmes there can me only one link
    def linked_resource
      self.datastreams["external_file"].content
    end

    def linked_resource=(value)
      self.datastreams["external_file"].content=value
    end

  end
end
