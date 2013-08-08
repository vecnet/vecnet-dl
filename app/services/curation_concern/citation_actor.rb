module CurationConcern
  class CitationActor < CurationConcern::BaseActor

    def create!
      curation_concern.apply_depositor_metadata(user.user_key)
      curation_concern.date_created = Date.today
      add_user_roles
      save
      create_files
    end

    def save
      curation_concern.attributes = attributes
      curation_concern.date_modified = Date.today
      curation_concern.set_visibility(visibility)
      curation_concern.save!
      #puts "Errors: #{curation_concern.errors.inspect}"
    end

    def update!
      super
      update_contained_citation_file_visibility
    end

    protected
    def add_user_roles
      curation_concern.apply_depositor_roles(user)
      curation_concern.save!
    end

    def files
      return @files if defined?(@files)
      @files = [attributes[:files]].flatten.compact
    end

    def create_files
      files.each do |file|
        create_citation_file(file)
      end
    end

    def create_citation_file(file)
      raise "#{file} file does not exist" unless File.exist?(file)
      cf=File.new(file)
      citation_file = CitationFile.new
      citation_file.batch = curation_concern
      citation_file.resource_type = "CitationFile"
      citation_file.file = cf
      Sufia::GenericFile::Actions.create_metadata(
          citation_file, user, curation_concern.pid
      )
      citation_file.set_visibility(visibility)
      attach_citation_file(citation_file, user, cf, File.basename(file))
      cf.close
    end

    def attach_citation_file(citation_file, user, file_to_attach, label)
      Sufia::GenericFile::Actions.create_content(
          citation_file,
          file_to_attach,
          label,
          'content',
          user
      )
    end

    def update_contained_citation_file_visibility
      if visibility_may_have_changed?
        curation_concern.citation_files.each do |f|
          f.set_visibility(visibility)
          f.save!
        end
      end
    end

  end
end
