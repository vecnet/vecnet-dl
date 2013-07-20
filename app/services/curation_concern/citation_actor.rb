module CurationConcern
  class CitationActor < CurationConcern::BaseActor

    def create!
      puts("Into create: #{curation_concern.inspect}")
      curation_concern.apply_depositor_metadata(user.user_key)
      curation_concern.date_created = Date.today
      add_user_roles
      create_files
      save
    end

    def save
      puts("into save")
      curation_concern.attributes = attributes
      curation_concern.date_modified = Date.today
      curation_concern.set_visibility(visibility)
      puts "Is valid: #{curation_concern.inspect}"
      curation_concern.save!
      #puts "Errors: #{curation_concern.errors.inspect}"
    end

    def update!
      super
      update_contained_generic_file_visibility
    end

    protected
    def add_user_roles
      curation_concern.apply_depositor_roles(user)
      curation_concern.save
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
      generic_file = GenericFile.new
      generic_file.type="endnote_citation"
      generic_file.file = file
      generic_file.batch = curation_concern
      Sufia::GenericFile::Actions.create_metadata(
          generic_file, user, curation_concern.pid
      )
      generic_file.set_visibility(visibility)
      CurationConcern.attach_file(generic_file, user, file)
    end

    def update_contained_generic_file_visibility
      if visibility_may_have_changed?
        curation_concern.generic_files.each do |f|
          f.set_visibility(visibility)
          f.save!
        end
      end
    end

  end
end
