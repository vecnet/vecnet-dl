require 'mods'
class CitationIngestService

  attr_accessor :metadata_file, :parsed_mods, :curation_concern, :pdf_paths

  def initialize(mods_input_file, pdf_paths = [])
    @metadata_file = mods_input_file
    @pdf_paths = pdf_paths
  end

  def ingest_citation
    actor.create!
    puts "Created Citation with id: #{@curation_concern.pid}"
    puts "Citation created as: #{Citation.find(@curation_concern.pid)}"
  rescue ActiveFedora::RecordInvalid=>e
    puts "Error occured during creation: #{e.inspect}"
  end

  def citation
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
    part= self.parsed_mods.part
    dt= self.parsed_mods.part.date.text
    part_detail={}
    part.detail.map{|n| part_detail[n.type_at.to_sym] = n.text}
    unit=part.extent.attribute("unit").value
    start_page=part.extent.start.text
    end_page=part.extent.end.text
    citation="#{title} #{part_detail[:volume]}, #{part_detail[:issue]} (#{dt}): #{unit} #{start_page}-#{end_page}"
  end

  private
  def resolve_pdf_path(fname)
    pdf_paths.each do |path|
      s = File.join(path, fname)
      return s if ::File.exists?(s)
    end
    puts "Could not locate file #{fname}"
    nil
  end

  def remove_newlines(s)
    s.gsub("\n","").strip
  end
end
