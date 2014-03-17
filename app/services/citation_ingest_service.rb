require 'mods'
class CitationIngestService
  class ModsExtractor
    attr_reader :mods
    def initialize(mods_fname)
      @mods = Mods::Record.new.from_str(File.read(mods_fname))
    end
    def creator
      @mods.plain_name.display_value
    end
    def description
      @mods.abstract.text
    end
    def title
      @mods.title_info.full_title
    end
    def cite_key
      @mods.cite_key
    end
    def curated_id
      @mods.identifier - self.cite_key).map { |i| remove_newlines(i.text) }.compact
    end
    def identifiers
      @mods.identifier.map {|i| remove_newlines(i.text) }.compact
    end
    def subjects
      @mods.subject.map do |sub|
        sub.text.gsub(/\n|\*/,"").strip
      end
    end
    def species
      NcbiSpeciesTerm.get_species_term(self.subjects).map(&:term).compact
    end
    def language
      @mods.language.map { |lang| remove_newlines(lang.text_term.text) }
    end
    def urls
      @mods.location.url.map { |loc| remove_newlines(loc.text) }
    end
    def related_urls
      self.urls.reject{|u| u.start_with?('internal-pdf:', 'C:/')}.compact
    end
    def journal_title
      @mods.related_item.map do |node|
        if node.type_at == "host"
          remove_newlines(node.titleInfo.text)
        end
      end.compact
    end
    def pub_date
      @mods.part.date.text
    end
    def bibliographic_citation
      journal = self.journal_title.first || ''
      part_detail = {}
      @mods.part.detail.each { |n| part_detail[n.type_at.to_sym] = n.text }
      volume = part_detail[:volume]
      issue = part_detail[:issue]
      format_volume = "#{volume}"
      format_volume += "(#{issue})" if issue
      start_page = end_page = nil
      unless self.part.extent.nil?
        start_page = @mods.part.extent.search(:start).text
        start_page = nil if start_page.blank?
        end_page = @mods.part.extent.search(:end).text
        end_page = nil if end_page.blank?
      end
      format_pages = case
                     when start_page && end_page then "#{start_page}-#{end_page}"
                     when start_page then "#{start_page}"
                     when end_page then "#{end_page}"
                     else ''
                     end
      date_text = @mods.part.date.text
      s = "#{journal}"
      s += " #{format_volume}" unless format_volume.blank?
      s += ", #{format_pages}" unless format_pages.blank?
      s += "." unless s.blank?
      s += " (#{date_text})" unless date_text.blank?
      s
    end

    private
    def remove_newlines(s)
      s.gsub("\n","").strip
    end
  end

  attr_accessor :metadata_file, :curation_concern, :pdf_paths

  def initialize(mods_input_file, pdf_paths = [])
    @mods = ModsExtractor(mods_input_file)
    @pdf_paths = pdf_paths
  end

  def ingest_citation
    #this is place to check if citation already exists in fedora
    citation = find_citation
    if citation.nil?
      actor = CurationConcern.actor(create_citation, job_user, extract_metadata)
      actor.create!
      logger.info "Created Citation with id: #{@curation_concern.noid}"
    else
      @curation_concern = citation
      actor = CurationConcern.actor(citation, job_user, extract_metadata)
      actor.update!
      logger.info "Updated Citation with id: #{@curation_concern.noid}"
    end
    @curation_concern.noid
  rescue ActiveFedora::RecordInvalid=>e
    logger.error "Error occured during creation: #{e.inspect}"
  end

  # see if this citation is already in fedora...
  # We first check our self-assigned id.
  # If there is more than one result we look for one with the exact same title.
  # Returns the Citation object if item is in fedora, otherwise returns nil
  def find_citation
    matches = Citation.where(desc_metadata__references_t: mint_a_citation_id).to_a
    case matches.length
    when 0 then nil
    when 1 then matches.first
    else
      matches.each do |r|
        return r if r.title == @mods.title
      end
      nil
    end
  end

  def create_citation
    @curation_concern ||= Citation.new(pid: CurationConcern.mint_a_pid)
  end

  def extract_metadata
    metadata = {
      files:        find_files_to_attach,
      title:        @mods.title,
      creator:      @mods.creator,
      identifier:   @mods.curated_id,
      description:  @mods.description,
      subject:      @mods.subjects,
      species:      @mods.species,
      language:     @mods.languages,
      resource_type:  'Article',
      source:       @mods.journal_title,
      references:   mint_a_citation_id, # mapped to dc type
      bibliographic_citation: @mods.bibliographic_citation,
      visibility:   AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      related_url:  @mods.related_urls,
      date_created: @mods.pub_date
    }
    #puts metadata.inspect
    return metadata
  end

  protected

  def mint_a_citation_id
    return @mods.title.sort.first[0..5] + @mods.pub_date
  end

  def job_user
    User.batchuser()
  end

  def find_files_to_attach
    related_url = @mods.urls
    related_url.map do |url|
      if url.start_with?('internal-pdf:', 'C:/')
        resolve_pdf_path(url.sub(/internal-pdf:\/\/|C:\//, ''))
      end
    end.compact
  end

  private
  def resolve_pdf_path(fname)
    pdf_paths.each do |path|
      logger.info "Find file #{fname} in path #{path.inspect}"
      s = File.join(path, fname)
      return s if ::File.exists?(s)
    end
    raise "Could not locate file #{fname} in paths #{pdf_paths.inspect}"
    nil
  end
end
