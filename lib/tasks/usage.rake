require 'uri'
require 'zlib'
namespace :vecnet do
  namespace :usage do

    desc "Harvest a single compressed nginx log file. file name is in HARVEST_FILE env variable"
    task :harvest_nginx => :environment do
      fname = ENV['HARVEST_FILE']
      unless fname.nil?
        HarvestNginx.parse_file_gz(fname)
      end
    end

    # copy holding information into the database to help create reports
    desc "Sync Fedora to Database"
    task :sync_fedora => :environment do
      SyncItemRecords.sync
    end
  end
end
