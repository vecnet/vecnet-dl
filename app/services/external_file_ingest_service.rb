require 'fileutils'
class ExternalFileIngestService

  class DirectoryCreation
    def self.mk_dir(path)
      FileUtils.mkdir_p(path)
    end
  end

  attr_accessor :external_file_path, :curation_concern, :absolute_source_path, :preservation_path, :url_to_ingest, :attributes

  def initialize(input_file_path, path_to_store = Rails.configuration.external_files_base_path )
    @external_file_path = input_file_path
    @preservation_path=path_to_store
  end

  def ingest_external_file
    create_generic_file
    assign_metadata
    actor.create!
    logger.info "Created Citation with id: #{@curation_concern.pid}"
    return  @curation_concern.noid
    rescue ActiveFedora::RecordInvalid=>e
    logger.error "Error occured during creation: #{e.inspect}"
    raise e
  end

  #May be this will be part of rake task? I m not sure yet
  def process_files_from_source
    Dir.foreach(external_file_path) do |f|
      @absolute_source_path= File.join(external_file_path,f)
      status = file_linked_status(f)
      if !file?(f) || !status.empty?
        logger.error "File #{f.inspect} already copied to preservation folder and linked in repository. Not ingested. Files exists in folders #{status.to_s}"
      else
        ingest_external_file
      end
    end
  end


  def file?(fname)
    return true if ::File.file?(File.join(external_file_path,fname))
    logger.warn("Need to skip #{fname} since it is not a file")
    return false
  end

  def file_linked_status(fname)
    return search_in_path(fname)
  end

  def create_generic_file
    @curation_concern ||= GenericFile.new(pid: CurationConcern.mint_a_pid)
    @curation_concern.batch=create_collection
  end

  def create_collection
    asset=Collection.create(pid: CurationConcern.mint_a_pid)
    return asset
  end

  def assign_metadata
    self.attributes=
    {
      linked_resource_url:create_directory_and_copy_file,
      visibility:AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
    }
  end

  def create_directory_and_copy_file
    directory_to_copy=File.join(@preservation_path, curation_concern.noid)
    DirectoryCreation.mk_dir(directory_to_copy) unless File.directory?(directory_to_copy)
    name = File.basename(@absolute_source_path)
    destination= File.join(directory_to_copy,name)
    FileUtils.cp(@absolute_source_path, destination)
    return destination if File.exists?(destination)
  end

  include Morphine
  register :actor do
    CurationConcern.actor(curation_concern, job_user, get_attributes)
  end

  protected

  def job_user
   User.batchuser()
  end

  def get_attributes
    return self.attributes
  end

  private
  def search_in_path(fname)
    logger.info "Find file #{fname} in path #{preservation_path.inspect} recursively"
    file_exist_status=[]
    Dir.glob(preservation_path + "**/"+ fname) do  |file|
      file_exist_status << file if ::File.exists?(file)
    end
    logger.error "Could not locate file #{fname} in paths #{preservation_path.inspect}. Need to ingest the file #{fname}. Status #{file_exist_status.inspect}"
    file_exist_status
  end
end
