module CurationConcern
  class GenericFileActor < CurationConcern::BaseActor
    def create!
      super
      add_user_roles
      update_file
      create_linked_external_file
    end

    def update!
      super
      update_file
      add_external_file
    end

    def rollback
      update_version
    end

  protected

    def add_user_roles
      curation_concern.apply_depositor_roles(user)
      curation_concern.save
    end

    def update_file
      #TODO handle new external file path and the fact that there is no content
      file = attributes.delete(:file)
      title = attributes[:title]
      title ||= file.original_filename if file
      curation_concern.label = title
      if file
        CurationConcern.attach_file(curation_concern, user, file)
      end
    end

    def linked_resource_urls
      @linked_resource_urls ||= Array(attributes[:linked_resource_urls]).flatten.compact
    end

    def create_linked_external_file
      #TODO Handle multiple links
      #linked_resource_urls.all? do |link_resource_url|
        #verify attach external file to curation concern
        create_linked_resource(link_resource_url)
      #end
    end

    def create_linked_resource(link_resource_url)
      return true if ! link_resource_url.present?
      curation_concern.linked_resource= link_resource_url
      curation_concern.save!
    end

    def update_version
      version_to_revert = attributes.delete(:version)
      return true if version_to_revert.blank?
      return true if version_to_revert.to_s ==  curation_concern.current_version_id
      revision = curation_concern.content.get_version(version_to_revert)
      mime_type = revision.mimeType.empty? ? "application/octet-stream" : revision.mimeType
      options = { label: revision.label, mimeType: mime_type, dsid: 'content' }
      curation_concern.add_file_datastream(revision.content, options)
      curation_concern.record_version_committer(user)
      curation_concern.save!
    end
  end
end
