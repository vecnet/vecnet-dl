require 'uri'
require 'zlib'
namespace :vecnet do
  namespace :usage do

    desc "Harvest a directory of compressed nginx log files. directory is in HARVEST_DIR env variable. Optional path to state file in HARVEST_STATE."
    task :harvest_nginx => :environment do
      hdir = ENV['HARVEST_DIR']
      hstate = ENV['HARVEST_STATE']
      unless hdir.nil?
        HarvestNginx.slurp_directory(hdir, 'access.log-*.gz', hstate)
      end
    end

    # copy holding information into the database to help create reports
    desc "Sync Fedora to Database"
    task :sync_fedora => :environment do
      SyncItemRecords.sync
    end
  end
end
