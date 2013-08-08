require 'mods'
require 'ostruct'
class CitationIngestService
  class PartExtractor
    attr_reader :unit, :count, :dt,:details, :start_page, :end_page, :part, :title
    def initialize(part_node,title)
      @title=title
      @part=part_node
      @count = 0
      extract_part
    end

    def extract_part
      @dt= self.part.date.text
      part_detail={}
      self.part.detail.map{|n| part_detail[n.type_at.to_sym] = n.text}
      @details=OpenStruct.new(part_detail)
      unless self.part.extent.nil?
        extract_extent(@part.extent)
      end
    end
    def extract_extent(extent)
      @unit= extent.unit.nil? ? "" : extent.unit.first
      @start_page= extent.search(:start).text
      @end_page= extent.search(:end).text
    end

    def volume
      @details.respond_to?(:volume) ? @details.volume : ""
    end

    def issue
      @details.respond_to?(:issue) ? @details.issue : ""
    end

    def citation
      "#{@title} #{volume}, #{issue} (#{dt}): #{unit_details}"
    end

    def unit_details
      unless unit.blank?
        "#{@unit} #{@start_page} - #{@end_page}"
      end
    end
  end

  attr_accessor :metadata_file, :parsed_mods, :curation_concern, :pdf_paths

  def initialize(mods_input_file, pdf_paths = [])
    @metadata_file = mods_input_file
    @pdf_paths = pdf_paths
  end

  def ingest_citation
    citation= find_citation
    unless citation.nil?
      logger.error "Atleast one Citation is exists in Fedora with id #{citation.id}. Not ingested."
      return
    end
    actor.create!
    logger.info "Created Citation with id: #{@curation_concern.pid}"
    return  @curation_concern.noid
  rescue ActiveFedora::RecordInvalid=>e
    logger.error "Error occured during creation: #{e.inspect}"
  end

  def find_citation
     if Citation.where(:desc_metadata__identifier_t=>get_identifiers).nil?
      return nil
    else
      return Citation.where(:desc_metadata__identifier_t=>get_identifiers).first
    end
  end

  def create_citation
    # TODO: this is place to check if citation already exists in fedora
    @curation_concern ||= Citation.new(pid: CurationConcern.mint_a_pid)
  end

  def parse_mods
    @parsed_mods ||= Mods::Record.new.from_str(File.read(self.metadata_file))
  end

  def extract_metadata
    if self.parsed_mods.nil?
      @parsed_mods=parse_mods
    end
    metadata=
    {
      files:find_files_to_attach,
      title:get_title,
      creator: self.parsed_mods.plain_name.display_value,
      identifier: get_identifiers, #identifier
      #genre:self.parsed_mods.genre.text ,
      #note:self.parsed_mods.note.text ,
      description:self.parsed_mods.abstract.text, #description
      subject:get_subjects,
      language:get_languages,   #language
      resource_type:self.parsed_mods.typeOfResource.text, #mapped to dc type
      bibliographic_citation:get_bibliographic_citation,
      visibility:AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    }
    #based_near:self.parsed_mods.get_location,   #based_near
    #self.parsed_mods.temporal,              #Mapped to dc temporal
    #self.parsed_mods.geographic} #Mapped spatial (but this is location name, so should be mapped to based_near?)
    #creator, #publisher, #contributor
    #date_created, date_modified, date_uploaded
    #puts metadata.inspect
    return metadata
  end

  include Morphine
  register :actor do
    CurationConcern.actor(create_citation, job_user, extract_metadata)
  end

  protected

  def job_user
   User.batchuser()
  end

  def get_title
    self.parsed_mods.title_info.full_title
  end

  def get_identifiers
    self.parse_mods.identifier.text
  end

  def get_subjects
    self.parse_mods.subject.map{|sub| sub.text.gsub("\n","").strip}
  end

  def get_languages
    self.parse_mods.language.map{|lang| lang.text.gsub("\n","").strip}
  end

  def get_urls
    self.parse_mods.location.url.map {|loc| loc.text.gsub("\n","").strip}
  end

  def find_files_to_attach
    related_url = get_urls
    related_url.map do |url|
      if url.start_with?('internal-pdf:', 'C:/')
        resolve_pdf_path(url.sub(/internal-pdf:\/\/|C:\//, ''))
      end
    end.compact
  end

  def get_bibliographic_citation
    title=''
    self.parsed_mods.related_item.each do |node|
      if node.type_at == "host"
        title=node.titleInfo.text.gsub("\n","").strip
      end
    end
    part= PartExtractor.new(self.parsed_mods.part,title)
    citation=part.citation
    return citation
  end

  private
  def resolve_pdf_path(fname)
    pdf_paths.each do |path|
      logger.info "Find file #{fname} in path #{path.inspect}"
      s = File.join(path, fname)
      return s if ::File.exists?(s)
    end
    logger.error "Could not locate file #{fname} in paths #{pdf_paths.inspect}"
    nil
  end

  def remove_newlines(s)
    s.gsub("\n","").strip
  end
end
