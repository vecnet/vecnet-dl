require 'pub_ticket'
class HarvestNginx
  # utility class to help with filtering out lines
  class LineRecord
    attr_accessor :ip, :event_time, :method, :path, :status, :agent,
      :user, :event, :pid, :pubtkt

    # save this as a UsageEvent in the database
    def save
      self.parse_pubtkt
      ue = UsageEvent.new
      ue.ip_address = ip
      ue.event_time = event_time
      ue.event = event
      ue.username = user
      ue.pid = pid
      ue.parent_pid = lookup_parent(pid)
      ue.agent = agent
      ue.save
    end

    def parse_pubtkt
      # we don't care whether the ticket is valid
      return nil if pubtkt.nil?
      pt = PubTicket.new(pubtkt)
      self.user = pt.uid
    end

    # find the parent of the item having id.
    # returns nil if the item is not in the DL.
    def lookup_parent(id)
      obj = ActiveFedora::Base.find("vecnet:" + id)
      return obj.batch.noid if obj.class == CitationFile
      id
    rescue
      nil
    end
  end

  def self.handle_one_record(r)
    return unless r.status == "200"
    return unless r.method == "GET"
    return if r.agent =~ /(bot|spider|yahoo)/i
    return if r.agent =~ /ruby/i    # our solr harvester agent

    # since all paths are rooted, the first index is always ""
    p = r.path.split('/')
    id = nil

    case p[1]
    when "downloads"
      return if r.path.index("thumbnail") # don't record thumbnail downloads
      r.event = "download"
      id = p[2]
    when "files", "citations"
      r.event = "view"
      id = p[2]
    when "concern"
      case p[2]
      when "generic_files", "citations"
        r.event = "view"
        id = p[3]
      end
    when "catalog" && p.length == 3
      r.event = "view"
      id = p[2]
    end
    return if id.nil?
    # don't record API accesses
    return if id.end_with?("xml") || id.end_with?("json")
    # remove any prefixes (they shouldn't be there, but make sure)
    id.gsub!('vecnet:', '')
    r.pid = id
    r.save
  end

  def self.parse_file_gz(fname)
    Zlib::GzipReader.open(fname).each_line do |line|
      r = LineRecord.new
      fields = line.split('|')
      r.ip = fields[0]
      r.event_time = DateTime.strptime(fields[2], "%d/%b/%Y:%H:%M:%S %z")
      r.method, r.path = fields[3].split
      r.status = fields[4]
      r.agent = fields[7]

      pt = URI.unescape(fields[11]).strip
      r.pubtkt = pt == '-' ? nil : pt

      handle_one_record(r)
    end
  end

  # Ingest all *.gz files in the given directory
  # File names ingested will be saved to the file
  # `state_fname`, if given. This will prevent files
  # from being ingested more than once.
  def self.slurp_directory(dirname, pattern, state_fname=nil)
    # keep two lists so files which are deleted are removed
    # from the state_fname file
    past_files = []
    ingested_files = []
    if state_fname
      past_files = JSON.parse(File.read(state_fname))
    end

    Dir.glob(pattern) do |fname|
      ingested_files << fname
      next if past_files.include?(fname)
      self.parse_file_gz(fname)
    end

    if state_fname
      File.open(state_fname, "w") do |f|
        f.write(JSON.generate(ingested_files)
      end
    end
  end
end
