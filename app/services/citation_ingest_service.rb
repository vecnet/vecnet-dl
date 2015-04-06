require 'uri'
class CitationIngestService
  class EndnoteExtractor
    attr_reader :endnote
    def initialize(endnote_hash)
      @endnote = endnote_hash
    end
    def creator
      @endnote[:author]
    end
    def description
      return [] if @endnote[:abstract].nil?
      [@endnote[:abstract].join(" ")]
    end
    def title
      [@endnote[:title].join(" ")]
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
    def keywords
      @endnote[:label]
    end
    def species
      return nil if self.subjects.nil?
      NcbiSpeciesTerm.get_species_term(self.subjects).map(&:term).compact
    end
    def language
      @endnote[:language]
    end
    def urls
      @urls if @urls
      @urls = @endnote[:url] || []
      @urls += @endnote[:files] || []
      @urls.map! { |u| URI.unescape(u) }  # apparently the file names are uri escaped
    end
    def related_urls
      return [] if self.urls.nil?
      result = self.urls.reject{|u| u.start_with?('internal-pdf:', 'C:/')}.compact
      result.reject! { |u| u.match(/<go to isi>/i) }
      result.map{|u| u.gsub("/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Citation&list_uids=","/pubmed/")}
    end
    def all_journal_titles
      [@endnote[:journal],
       @endnote[:title_alternate],
       @endnote[:title_secondary]].flatten.compact
    end
    def journal_title_long
      all_journal_titles.max_by &:length
    end
    def journal_title_short
      all_journal_titles.min_by &:length
    end
    def pub_date
      s = @endnote[:publish_year]
      s.nil? ? "" : s.first
    end
    def notes
      @endnote[:research_notes]
    end
    def locations
      return [] if @endnote[:call_number].nil?
      @locations ||= @endnote[:call_number].select { |item| parse_time(item).nil? }
    end
    def time_periods
      return [] if @endnote[:call_number].nil?
      @time_periods ||= @endnote[:call_number].map { |item| parse_time(item) }.compact
    end
    def bibliographic_citation
      return nil if journal_title_short.nil?
      s = format_if_present("{}", [journal_title_short])
      s += format_if_present(" {}", @endnote[:volume])
      s += format_if_present("({})", @endnote[:issue_number])
      s += format_if_present(", {}", @endnote[:pages])
      s += "."
      cite_date = @endnote[:date].first if @endnote[:date]
      cite_year = @endnote[:publish_year].first if @endnote[:publish_year]
      d = ""
      d = cite_date if cite_date
      d += " " if cite_date && cite_year
      d += cite_year if cite_year
      s += " (#{d})" unless d.blank?
      return s
    end
    def open_access?
      f = @endnote[:research_notes]
      return false if f.nil?
      f.each do |s|
        return true if /(global|open)\s+access/i.match(s)
      end
      false
    end

    private
      def format_if_present(format, v)
        return "" if v.nil? || v.blank?
        v = v.first if v.respond_to?(:first)
        format.gsub("{}",v)
      end

      def parse_time(s)
        t = Temporal.from_s(s)
        t.nil? ? nil : t.to_s
      end
  end

  attr_accessor :curation_concern, :pdf_paths

  def initialize(pdf_paths = [], endnote_record=nil, upload_files=true)
    if endnote_record
      @record = EndnoteExtractor.new(endnote_record)
    else
      throw "Record Source Required"
    end
    @pdf_paths = pdf_paths
    @upload_files = upload_files
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
    output e.backtrace
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
      title:        @record.title,
      creator:      @record.creator,
      identifier:   @record.curated_id,
      description:  @record.description,
      subject:      @record.subjects,
      tag:          @record.keywords,
      species:      @record.species,
      language:     @record.language,
      based_near:   @record.locations,
      start_time:   @record.time_periods,
      resource_type:  'Article',
      source:       @record.journal_title_long,
      references:   mint_a_citation_id, # mapped to dc type
      bibliographic_citation: @record.bibliographic_citation,
      visibility:   AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
      related_url:  @record.related_urls,
      date_created: @record.pub_date,
      open_access:  @record.open_access?
    }
    if @upload_files
      metadata[:files] = find_files_to_attach
    end
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
    return result.compact
  end

  private
  def resolve_pdf_path(fname)
    pdf_paths.each do |path|
      logger.info "Find file #{fname} in path #{path.inspect}"
      s = File.join(path, fname)
      return s if ::File.exists?(s)
    end
    # sometimes the files have a colon in the name ':', but the
    # filename in the record has the colon double escaped, so
    # after the first unescaping it is still '%3A'
    if fname =~ /%3A/
      alternate_fname = fname.gsub('%3A', ':')
      return resolve_pdf_path(alternate_fname)
    end
    output "Could not locate file #{fname} in paths #{pdf_paths.inspect}"
    nil
  end

  def output(text)
    logger.info(text)
    puts text
  end
end
