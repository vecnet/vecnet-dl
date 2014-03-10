require 'zlib'

# Given a rails log file, create a sequence of hashes, each having the keys
# :path :method :ip :user :date :status :duration
class LogParser

  def initialize(fname)
    @fname = fname
    @reader = File
    self
  end

  def use_gzip
    @reader = Zlib::GzipReader
    self
  end

  def each(&block)
    @reader.open(@fname) do |f|
      scan(f, &block)
    end
  end

  # reads f and extracts each request into a hash, which is then yielded.
  # Hashes are passed to the block as they are created
  def scan(f, &block)
    start_line    = /^Started (?<method>\w+) "(?<path>[^"]+)" for (?<ip>\S+) at (?<date>.*?)$/
    pubtkt_line   = /^Pubtkt:.*?User: (?<user>\w+),/
    complete_line = /^Completed (?<status>\d+).*?in (?<duration>\d+)ms/
    state = :look_for_start
    info = {}
    f.each_line do |line|
      case line
      when start_line
        m = $~  # save in case $~ is altered in the yield
        yield info if state == :in_body
        info = {method: m[:method],
                path:   m[:path],
                ip:     m[:ip],
                date:   m[:date],
        }
        state = :in_body
      when pubtkt_line
        next unless state == :in_body
        info[:user] = $~[:user]
      when complete_line
        next unless state == :in_body
        info[:status] = $~[:status]
        info[:duration] = $~[:duration]
        yield info
        info = {}
        state = :look_for_start
      end
    end
    # in case there is a missing Completed line...
    yield info if state == :in_body
  end

end
