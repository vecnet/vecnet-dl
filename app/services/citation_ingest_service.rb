require 'mods'
class CitationIngestService

  attr_accessor :metadata_file, :parsed_mods, :curation_concern, :pdf_path

  def initialize(mods_input_file, path_to_files)
    @metadata_file = mods_input_file
    @pdf_file= path_to_files
  end

  def ingest_citation
    actor.create!
    puts "Created Citation with id: #{@curation_concern.pid}"
    puts "Citation created as: #{Citation.find(@curation_concern.pid)}"
  rescue ActiveFedora::RecordInvalid
    puts "Error occured during creation: #{@curation_concern.errors.inspect}"
  end

  def citation
    @curation_concern ||= Citation.new(pid: CurationConcern.mint_a_pid)
  end

  def parse_mods
    @parsed_mods = Mods::Record.new
    @parsed_mods.from_str(File.read(self.metadata_file))
  end

  def extract_metadata
    if self.parsed_mods.nil?
      @parsed_mods=parse_mods
    end
    metadata=
    {
      files:find_files_to_attach.map{|file|File.read(file)},
      title:"add title",
      creator: self.parsed_mods.plain_name.display_value,
      identifier: get_identifiers, #identifier
      #genre:self.parsed_mods.genre.text ,
      #note:self.parsed_mods.note.text ,
      description:self.parsed_mods.abstract.text, #description
      subject:get_subjects,
      language:get_languages,   #language
      resource_type:self.parsed_mods.typeOfResource.text, #mapped to dc type
      bibliographic_citation:get_bibliographic_citation,
      visibility:AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC}
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
    CurationConcern.actor(citation, job_user, extract_metadata)
  end

  protected

  def job_user
   User.batchuser()
  end

  def get_identifiers
    self.parse_mods.identifier.text
  end

  def get_subjects
    subject=[]
    self.parse_mods.subject.each{|sub| subject << sub.text.gsub("\n","").strip}
    return subject
  end

  def get_languages
    language=[]
    self.parse_mods.language.each{|lang| language << lang.text.gsub("\n","").strip}
    return language
  end

  def get_urls
    url=[]
    self.parse_mods.location.text.each {|loc| url << loc.gsub("\n","").strip}
    return url
  end

  def find_files_to_attach
    related_url=get_urls
    files=[]
    related_url.each do |url|
      if (url =~ /internal-pdf(.*)/)
       files<< url.gsub("internal-pdf://", self.pdf_path)
      end
    end
    files
  end

  def get_bibliographic_citation
    title=''
    self.parsed_mods.related_item.each do |node|
      if node.type_at == "host"
        title=node.titleInfo.text.gsub("\n","").strip
      end
    end
    part= self.parsed_mods.part
    dt= self.parsed_mods.part.date.text
    part_detail={}
    part.detail.map{|n| part_detail[n.type_at.to_sym] = n.text}
    unit=part.extent.attribute("unit").value
    start_page=part.extent.start.text
    end_page=part.extent.end.text
    citation="#{title} #{part_detail[:volume]}, #{part_detail[:issue]} (#{dt}): #{unit} #{start_page}-#{end_page}"
  end


end