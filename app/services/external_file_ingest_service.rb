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
    return  @curation_concern.noid
    logger.info "Created Citation with id: #{@curation_concern.pid}"
    rescue ActiveFedora::RecordInvalid=>e
    logger.error "Error occured during creation: #{e.inspect}"
  end

  #May be this will be part of rake task? I m not sure yet
  def process_files_from_source
    Dir.foreach(external_file_path) do |f|
      @absolute_source_path=File.join(external_file_path,f)
      unless file_preserved_status.empty?
        logger.error "File #{f.inspect} already copied to preservation folder. Not ingested. Files exists in folders #{file_preserved_status.to_s}"
      else
        ingest_external_file
      end
      logger.warn("Skipping #{s} since it is not a file")
    end
  end

  def file_preserved_status(fname)
    return search_in_path(fname)
  end

  def file_not_preserved?(fname)
    #TODO add check if given file path already exist in preservation_path
    return false unless ::File.file?(@absolute_source_path)
    files_preserved=search_in_path(fname)
    return true if files_preserved.empty?
    return false
  end

  def create_generic_file
    @curation_concern ||= GenericFile.new(pid: CurationConcern.mint_a_pid)
  end

  def parsed_mods
    return @parsed_mods if defined?(@parsed_mods)
    @parsed_mods = Mods::Record.new.from_str(File.read(self.metadata_file))
  end

  def assign_metadata
    self.attributes=
    {
      linked_resource_urls:create_directory_and_copy_file,
      visibility:AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
    }
  end

  def create_directory_and_copy_file
    directory_to_copy=File.join(@preservation_path, curation_concern.id)
    DirectoryCreation.mk_dir(directory_to_copy) unless File.directory?(directory_to_copy)
    name = File.basename(@absolute_source_path)
    destination= File.join(directory_to_copy,name)
    FileUtils.cp(@absolute_source_path, dest_folder)
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

  def get_file_location
    #TODO Create Pid directory inside repository path
    #TODO copy file from external_file_path to pid directory
    #return absolute path of repository path
    return 'need to return right path'
  end

  private
  def search_in_path(fname)
    logger.info "Find file #{fname} in path #{preservation_path.inspect} recursively"
    file_exist_status=[]
    Dir.glob(preservation_path + "**/"+ fname) do  |file|
      file_exist_status << file if ::File.exists?(file)
    end
    logger.error "Could not locate file #{fname} in paths #{preservation_path.inspect}. Need to ingest the file #{fname}"
    file_exist_status
  end
end


Dir.glob(test_dir + "**/"+ fname) { |file|  return file if ::File.exists?(file)}