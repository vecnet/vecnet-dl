module CurationConcern
  class CitationActor < CurationConcern::BaseActor

    def create!
      curation_concern.apply_depositor_metadata(user.user_key)
      curation_concern.date_uploaded = Date.today
      curation_concern.apply_depositor_roles(user)
      save
      attach_files
    end

    def save
      @open_access = attributes.fetch(:open_access, false)
      attributes.delete(:open_access)
      @files = [attributes[:files]].flatten.compact
      attributes.delete(:files)

      curation_concern.attributes = attributes
      curation_concern.date_modified = Date.today
      curation_concern.set_visibility(visibility)
      curation_concern.save!
      #puts "Errors: #{curation_concern.errors.inspect}"
    end

    def update!
      curation_concern.apply_depositor_metadata(user.user_key)
      save
      attach_files
    end

    protected

    def files
      return @files if defined?(@files)
      @files = [attributes[:files]].flatten.compact
    end

    def attach_files
      files.each do |fname|
        raise "#{fname} file does not exist" unless File.exist?(fname)
        # see if a file with this name and size is already attached
        gf = find_attached(fname)
        if gf.nil?
          create_citation_file(fname)
        else
          # Assume file size is different if and only if file is different.
          # This assumption is probably wrong. What is a better check? a hash?
          if gf.file_size.first.to_i != File.size(fname)
            update_citation_file(gf, fname)
          end
        end
      end
    end

    # is the file with the given name already attached to
    # this curation concern? Return the AF model if so, nil otherwise.
    def find_attached(fname)
      fname = File.basename(fname)
      curation_concern.generic_files.each do |gf|
        return gf if gf.filename == fname
      end
      nil
    end

    def create_citation_file(fname)
      citation_file = CitationFile.new
      citation_file.batch = curation_concern
      citation_file.resource_type = "CitationFile"
      Sufia::GenericFile::Actions.create_metadata(
          citation_file, user, curation_concern.pid
      )
      update_citation_file(citation_file, fname)
    end

    def update_citation_file(gf, fname)
      File.open(fname, "rb") do |f|
        gf.file = f
        if @open_access
          gf.set_visibility(AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        else
          gf.set_visibility(AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        end
        Sufia::GenericFile::Actions.create_content(
            gf,
            f,
            File.basename(fname),
            'content',
            user
        )
      end
    end

    # is this method used at all??
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
