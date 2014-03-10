#
# Decode and Summarize a set of log files for the VecNet Project.
#
# This is designed to be run as a batch task on a local machine having
# copies of the server's rails log files. The "right way" to do this is
# to have the task run on the server, on some periodic basis. For starters,
# it will make the code for retreiving the item information form the server
# simpler. Right now this script can only report on the the public entries
# since it is not using any kind of auth keys to view the private items.
#
# We track, on a monthly basis
#  * total page hits, by user or anonymous
#  * item views
#  * item downloads (not including thumbnails)
#  * Any search done more than 10 times
require 'log_parser'
require 'rest_client'
require 'json'

class VecnetUsage

  attr_accessor :users, :views, :downloads, :error_count, :hit_count,
    :valid_count, :subjects, :resource_types, :locations

  def initialize
    @users = {}       # hash of userid => count
    @views = {}       # hash of pid => count
    @downloads = {}   # hash of pid => count
    @searches = {}    # hash of string => count
    @ips = {}         # hash of ipaddr => count
    @error_count = 0  # count of 500 statuses
    @hit_count = 0    # total number of accesses...including spam
    @valid_count = 0  # total number of non spam accesses
    @item_info = {}   # cache for getting item titles, subjects, etc.
    @subjects = {}    # hash of string => count
    @resource_types = {}  # hash of string => count
    @locations = {}   # hash of string => count
  end

  def scan_file(fname)
    lp = LogParser.new(fname).use_gzip
    lp.each do |item|
      @hit_count += 1
      next if ["401", "404"].include?(item[:status])

      @valid_count += 1
      @error_count += 1 if item[:status] == "500"

      u = item[:user] || "anonymous"
      @users[u] = 1 + (@users[u] || 0)

      ip = item[:ip] || "none"
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
        update_item_counts(pid)
      # "/downloads/:pid"
      when %r{^/downloads/(?<pid>\w\w\d\d\w\w\d\d\w)(/\d+)?$}
        # leave off "?datastream_id=thumbnail" on purpose 
        pid = $~[:pid]
        @downloads[pid] = 1 + (@downloads[pid] || 0)
        update_item_counts(pid)
      when %r{^/\?}
        s = p[2..-1]
        @searches[s] = 1 + (@searches[s] || 0)
      end
    end
  end

  def update_item_counts(pid)
    item = get_item_info(pid)
    update_count_from_list(@locations, item[:based_near])
    update_count_from_list(@subjects, item[:subject])
    update_count_from_list(@resource_types, item[:resource_type])
  end

  def update_count_from_list(table, lst)
    return if lst.nil?
    lst.each { |s| table[s] = 1 + (table[s] || 0) }
  end


  def output_results
    print "Total Hits #{@hit_count}\n"
    print "Valid Hits #{@valid_count}\n"
    print "Total Errors #{@error_count}\n"
    output_values("Users", @users)
    output_values("IPs", @ips, max_items: 25)
    output_values("Views", @views, show_titles: true)
    output_values("Downloads", @downloads, show_titles: true)
    output_values("Resource Types", @resource_types, sub_heading: "Either viewed or downloaded")
    output_values("Subjects", @subjects, sub_heading: "Either viewed or downloaded")
    output_values("Locations", @locations, sub_heading: "Either viewed or downloaded")
    output_values("Searches", @searches, max_items: 50)
  end

  # options are
  # :max_items      = output at most max_items (defaults to 10,000)
  # :min_threshold  = do not output anything with value <= min_threshold
  # :show_titles    = replace values with item titles? (default to false)
  # :sub_heading    = text to be printed under title
  # if both options are passed, items are displayed until at least one holds
  def output_values(title, m, options={})
    print "========== ", title, " ==========\n"
    puts  options[:sub_heading] if options[:sub_heading]
    printf "%10s, %s\n", "Count", "Value"
    printf "%10s, %s\n", "-----", "-----"
    count = 0
    max_items = options[:max_items] || 10000
    threshold = options[:min_threshold] || 0
    entries = m.sort_by {|k,v| v}.reverse
    entries.each do |k,v|
      break if v.is_a?(Integer) && v <= threshold
      if options[:show_titles]
        item = get_item_info(k)
        k = "(#{k}) #{item[:title]}"
      end
      printf "%10s, %s\n", v, k
      count += 1
      break if count >= max_items
    end
  end

  # connect to application and get the
  #   :title (string),
  #   :based_near (array of string),
  #   :resource_type (array of string)
  #   :subject (array of string)
  # for the given item. returns hash.
  def get_item_info(pid)
    @item_info[pid] ||= query_library(pid)
  end

  def query_library(pid)
    r = RestClient.get "https://dl.vecnet.org/files/#{pid}.json", Cookie: authCookie
    info = JSON.parse(r)["generic_file"]
    {title:         info["title"],
     based_near:    info["metadata"]["based_near"],
     resource_type: info["metadata"]["resource_type"],
     subject:       info["metadata"]["subject"]
    }
  rescue RestClient::Exception, JSON::ParserError
    {}
  end

  # hack to get restricted files
  def authCookie
    "auth_pubtkt=uid%3D..."
  end

end
