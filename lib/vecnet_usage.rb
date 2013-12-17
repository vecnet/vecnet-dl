#
#
# We track, on a monthly basis
#  * total page hits, by user or anonymous
#  * item views
#  * item downloads (not including thumbnails)
#  * Any search done more than 10 times
class VecnetUsage

  attr_accessor :users, :views, :downloads, :error_count, :hit_count

  def initialize
    @users = {}       # hash of userid => count
    @views = {}       # hash of pid => count
    @downloads = {}   # hash of pid => count
    @searches = {}    # hash of string => count
    @ips = {}         # hash of ipaddr => count
    @error_count = 0  # count of 500 statuses
    @hit_count = 0    # total number of accesses...including spam and other crap
  end

  def scan_file(fname)
    lp = LogParser.new(fname).use_gzip
    lp.each do |item|
      @hit_count += 1
      next if ["401", "404"].include?(item[:status])

      @error_count += 1 if item[:status] == "500"

      u = item[:user] || "anonymous"
      @users[u] = 1 + (@users[u] || 0)

      ip = item[:ip]
      @ips[ip] = 1 + (@ips[ip] || 0)

      next unless item[:method] == "GET"

      p = item[:path]
      case p
      # "/citations/:pid"
      # "/concern/citations/:pid"
      # "/concern/generic_files/:pid/edit"
      # "/concern/generic_files/:pid"
      when %r{^/(files|citations|concern/(citations|generic_files))/(?<pid>\w\w\d\d\w\w\d\d\w)(/\d+)?(\.json)?$}
        pid = $~[:pid]
        @views[pid] = 1 + (@views[pid] || 0)
      # "/downloads/:pid"
      when %r{^/downloads/(?<pid>\w\w\d\d\w\w\d\d\w)(/\d+)?$}
        # leave off "?datastream_id=thumbnail" on purpose 
        pid = $~[:pid]
        @downloads[pid] = 1 + (@downloads[pid] || 0)
      when %r{^/\?}
        s = p[2..-1]
        @searches[s] = 1 + (@searches[s] || 0)
      end
    end
  end

  def output_results
    puts "Total Hits",@hit_count
    puts "Total Errors",@error_count
    output_value("Users", @users)
    output_value("IPs", @ips)
    output_value("Views", @views)
    output_value("Downloads", @downloads)
    output_value("Searches", @searches)
  end

  # options are
  # :max_lines
  # :min_count
  def output_value(title, m, options={})
    puts title
    entries = m.sort_by {|k,v| v}.reverse
    entries.each do |k,v|
      print "#{k}, #{v}\n"
    end
  end

end
