require 'uri'
require 'zlib'
namespace :vecnet do
  namespace :usage do

    def parse_nginx_new
    end

    def parse_nginx_old
    end

    desc "Harvest a single compressed nginx log file. file name is in HARVEST_FILE env variable"
    task :harvest_nginx => :environment do
      fname = ENV['HARVEST_FILE']
      unless fname.nil?
        HarvestNginx.parse_file_gz(fname)
      end
    end
  end
end
