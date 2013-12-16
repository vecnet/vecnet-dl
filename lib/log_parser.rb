require 'zlib'

# Given a rails log file, turn it into a sequence of hashes
# each with the keys:
# :request :method :ip :user :time :status :duration
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
    start_line = /^Started (?<method>\w+) "(?<path>[^"]+)" for (?<ip>\S+) at (?<date>.*?)$/
    pubtkt_line = /^Pubtkt:.*?User: (?<user>\w+),/
    complete_line = /^Completed (?<status>\d+).*?in (?<duration>\d+)ms/
    state = :nothing
    info = {}
    f.each_line do |line|
      m = start_line.match(line)
      if m
        yield info if state == :in_body
        info = {method: m[:method],
                path: m[:path],
                ip: m[:ip],
                date: m[:date],
        }
        state = :in_body
        next
      end
      next unless state == :in_body
      m = pubtkt_line.match(line)
      if m
        info[:user] = m[:user]
        next
      end
      m = complete_line.match(line)
      if m
        info[:status] = m[:status]
        info[:duration] = m[:duration]
        yield info
        state = :nothing
      end
    end
    yield info if state == :in_body
  end

end
