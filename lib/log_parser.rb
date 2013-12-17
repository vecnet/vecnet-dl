require 'zlib'

# Given a rails log file, turn it into a sequence of hashes
# each with the keys:
# :path :method :ip :user :date :status :duration
class LogParser

  def scan_gzip(fname, &block)
    Zlib::GzipReader.open(fname) do |gzip|
      scan(gzip, &block)
    end
  end

  def scan_file(fname, &block)
    File.open(fname) do |f|
      scan(f, &block)
    end
  end

  # reads each line from f, extracting request information into a hash
  # hashes are passed to the block as they are read
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
