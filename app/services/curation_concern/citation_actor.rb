module CurationConcern
  class CitationActor < CurationConcern::BaseActor

    def create!
      curation_concern.apply_depositor_metadata(user.user_key)
      curation_concern.date_uploaded = Date.today
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
      @files = [attributes[:files]].flatten.compact
      attributes[:files] = nil
      curation_concern.apply_depositor_metadata(user.user_key)
      save
      update_files
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

    def update_files
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

    def find_attached(fname)
      fname = File.basename(fname)
      curation_concern.generic_files.each do |gf|
        return gf if gf.filename == fname
      end
      nil
    end

    def create_citation_file(fname)
      raise "#{fname} file does not exist" unless File.exist?(fname)
      File.open(fname, "rb") do |f|
        citation_file = CitationFile.new
        citation_file.batch = curation_concern
        citation_file.resource_type = "CitationFile"
        citation_file.file = f
        Sufia::GenericFile::Actions.create_metadata(
            citation_file, user, curation_concern.pid
        )
        attach_citation_file(citation_file, user, f, File.basename(fname))
      end
    end

    def update_citation_file(gf, fname)
      File.open(fname, "rb") do |f|
        gf.file = f
        attach_citation_file(gf, user, f, File.basename(fname))
      end
    end

    def attach_citation_file(citation_file, user, file_to_attach, label)
      if attributes[:open_access]
        citation_file.set_visibility(AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      else
        citation_file.set_visibility(AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      end
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
