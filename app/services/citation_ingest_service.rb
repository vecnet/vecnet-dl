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
      (@mods.identifier - self.cite_key).map { |i| remove_newlines(i.text) }.compact
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
    def notes
      nil
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

  class EndnoteExtractor
    attr_reader :endnote
    def initialize(endnote_hash)
      @endnote = endnote_hash
    end
    def creator
      @endnote[:author]
    end
    def description
      @endnote[:abstract]
    end
    def title
      @endnote[:title]
    end
    def curated_id
      return @ids if @ids
      @ids = []
      if @endnote[:doi]
        # not everything in the doi field is a doi.
        @ids += @endnote[:doi].map { |doi| doi[/10\.\d+\/\S+/] }.compact.map { |doi| "doi:#{doi}" }
      end
      if @endnote[:isbn]
        @ids += @endnote[:isbn].map { |issn| "issn:#{issn}" }
      end
      if @endnote[:accession_number]
        @ids += @endnote[:accession_number]
      end
      @ids = @ids.compact
    end
    def subjects
      @endnote[:keywords]
    end
    def species
      return nil if self.subjects.nil?
      NcbiSpeciesTerm.get_species_term(self.subjects).map(&:term).compact
    end
    def language
      @endnote[:language]
    end
    def urls
      @endnote[:url]
    end
    def related_urls
      return [] if self.urls.nil?
      result = self.urls.reject{|u| u.start_with?('internal-pdf:', 'C:/')}.compact
      result.map{|u| u.gsub("/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Citation&list_uids=","/pubmed/")}
    end
    def journal_title
      @endnote[:title_alternate] || @endnote[:journal]
    end
    def pub_date
      s = @endnote[:publish_year]
      s.nil? ? "" : s.first
    end
    def notes
      @endnote[:research_notes]
    end
    def bibliographic_citation
      s = format_if_present("{}", @endnote[:journal])
      s += format_if_present(" {}", @endnote[:volume])
      s += format_if_present("({})", @endnote[:issue_number])
      s += format_if_present(", {}", @endnote[:pages])
      s += "."
      cite_date = @endnote[:date].first if @endnote[:date]
      cite_year = @endnote[:publish_year].first if @endnote[:publish_year]
      d = ""
      d = cite_date if cite_date
      d += ", " if cite_date && cite_year
      d += cite_year if cite_year
      s += " (#{d})" unless d.blank?
      return s
    end

    private
      def format_if_present(format, v)
        return "" if v.nil? || v.blank?
        v = v.first if v.respond_to?(:first)
        format.gsub("{}",v)
      end
  end

  attr_accessor :metadata_file, :curation_concern, :pdf_paths

  def initialize(mods_input_file=nil, pdf_paths = [], endnote_record=nil)
    if mods_input_file
      @record = ModsExtractor.new(mods_input_file)
    elsif endnote_record
      @record = EndnoteExtractor.new(endnote_record)
    else
      throw "Record Source Required"
    end
    @pdf_paths = pdf_paths
  end

  def ingest_citation
    output "======"
    output "Looking up citation key #{mint_a_citation_id}"
    #this is place to check if citation already exists in fedora
    citation = find_citation
    if citation.nil?
      output "No citation found in fedora"
      actor = CurationConcern.actor(create_citation, job_user, extract_metadata)
      actor.create!
      output "Created Citation with id: #{@curation_concern.noid}"
    else
      output "Matching citation found in fedora: #{citation.noid}"
      @curation_concern = citation
      actor = CurationConcern.actor(citation, job_user, extract_metadata)
      actor.update!
      output "Updated Citation with id: #{@curation_concern.noid}"
    end
    @curation_concern.noid
  rescue ActiveFedora::RecordInvalid=>e
    output "Error occured during creation: #{e.inspect}"
  end

  # see if this citation is already in fedora...
  # We first check our self-assigned id.
  # If there is more than one result we look for one with the exact same title.
  # Returns the Citation object if item is in fedora, otherwise returns nil
  def find_citation
    matches = Citation.where(desc_metadata__references_t: mint_a_citation_id).to_a
    return nil if matches.length == 0
    matches.each do |r|
      return r if r.title == @record.title.first
    end
    nil
  end

  def create_citation
    @curation_concern ||= Citation.new(pid: CurationConcern.mint_a_pid)
  end

  def extract_metadata
    metadata = {
      files:        find_files_to_attach,
      title:        @record.title,
      creator:      @record.creator,
      identifier:   @record.curated_id,
      description:  @record.description,
      subject:      @record.subjects,
      species:      @record.species,
      language:     @record.language,
      resource_type:  'Article',
      source:       @record.journal_title,
      references:   mint_a_citation_id, # mapped to dc type
      bibliographic_citation: @record.bibliographic_citation,
      visibility:   AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      related_url:  @record.related_urls,
      date_created: @record.pub_date
    }
    #puts metadata.inspect
    return metadata
  end

  protected

  def mint_a_citation_id
    return @record.title.sort.first[0..5] + @record.pub_date
  end

  def job_user
    User.batchuser()
  end

  def find_files_to_attach
    possible_files = []
    possible_files += @record.urls if @record.urls
    result = []
    possible_files.each do |s|
      case
      # "C:/MAP/PDF/505.pdf"
      # "internal-pdf://a-file.pdf"
      when s[/^internal-pdf:\/\/(?<fname>.+)/], s[/^C:\/\/MAP\/PDF\/(?<fname>.+)/]
        result << $~["fname"]
      end
    end
    # only scan notes if we don't find a file in the url.
    if result.empty? && @record.notes
      @record.notes.each do |s|
      # the order of the when clauses is IMPORTANT
        case
        # "DONE - pdf 1254/4004"
        when s[/pdf (?<first>\d+)\/(?<second>\d\d+)/]
          result << $~["first"] + ".pdf"
          result << $~["second"] + ".pdf"
        # "no data - pdf 3246/7"
        when s[/pdf (?<first>\d+)\/(?<second>\d)/]
          n = $~["first"]
          result << n + ".pdf"
          result << n[0..-2] + $~["second"] + ".pdf"
        # "DONE - pdf 5810 CMa"
        when s[/pdf (?<fname>\d+)/]
          result << $~["fname"] + ".pdf"
        end
      end
    end
    output "Record refers to PDF files #{result}"
    result = result.map { |fname| resolve_pdf_path(fname) }
    output "Found PDF files #{result}"
    return result
  end

  private
  def resolve_pdf_path(fname)
    pdf_paths.each do |path|
      logger.info "Find file #{fname} in path #{path.inspect}"
      s = File.join(path, fname)
      return s if ::File.exists?(s)
    end
    output "Could not locate file #{fname} in paths #{pdf_paths.inspect}"
    nil
  end

  def output(text)
    logger.info(text)
    puts text
  end
end
