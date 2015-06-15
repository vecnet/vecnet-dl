#
# Tasks copied from to CurateND
#
require 'rake'
require 'fileutils'
require 'logger'
require File.expand_path('../../../app/script/convert_depositor', __FILE__)
namespace :vecnet do
  namespace :app do
    desc "Raise an error unless the RAILS_ENV is development"
    task :development_environment_only do
      raise "This task is limited to the development environment" unless Rails.env == 'development'
    end

    desc "Raise an error if the RAILS_ENV is production"
    task :restrict_from_production do
      raise "This task is restricted from the production environment" if Rails.env == 'production'
    end

    desc "Characterize uncharacterized files"
    task :characterize => :environment do
      if ENV['CONTENT_TYPE'].nil?
        raise "You must provide a content type using the format 'vecnet::app::characterize CONTENT_TYPE=GenericFile'."
      end
      klass=ENV['CONTENT_TYPE'].constantize
      klass.find(:all, :rows => klass.count).each do |gf|
        if gf.characterization.content.nil?
          Resque.enqueue(CharacterizeJob, gf.pid)
        end
      end
    end
  end

  def timed_action(action_name, &block)
    start_time = Time.now
    logger.info("\t ############ Starting #{action_name} at #{start_time} ")
    yield
    end_time = Time.now
    time_taken = end_time - start_time
    logger.info("\t ############ Complete #{action_name} at #{end_time}, Duration #{time_taken.inspect} ")
  end

  desc "Set APIKEY key for the user UID (creating if necessary)"
  task :set_api_key => :environment do
    key = ENV["APIKEY"]
    uid = ENV["UID"]
    if uid.nil? || key.nil?
      raise "Set UID and APIKEY env vars"
    end
    u = User.find_by_api_key(key)
    u = User.find_by_uid(uid) if u.nil?
    u = User.new(uid: uid) if u.nil?
    if u.uid == uid
      if ENV["GROUP_LIST"]
        u.group_list = ENV["GROUP_LIST"].split
      end
      u.api_key = key
      u.save
    else
      raise "Different user #{u.uid} already has the api key #{key}"
    end
  end


  desc "Dump repository contents to file named $OUTFILE or STDOUT"
  task :dump_statistics => :environment do
    timed_action "Dumping Statistics" do
      if ENV['OUTFILE']
        DumpRepository.run_to_file(ENV['OUTFILE'])
      else
        DumpRepository.run(STDOUT)
      end
    end
  end

  desc "Convert depositor email to username"
  task :depositor_conversion => :environment do
    timed_action "to convert all user id on depositor and edit persons to new UID scheme" do
      ConvertDepositor.all_repo_objects
    end
  end

  desc "Solrize everything"
  task :solrize => :environment do
    ActiveFedora::Base.find_each do |obj|
      obj.update_index
    end
  end

  namespace :destroy do
    desc "Remove all citations in the given environment"
    task :citation => :environment do
      timed_action "destroy citations" do
        Citation.find(:all).each{|c| c.destroy}
      end
    end
  end


  namespace :solrize_synonym do
  desc "get all synonym and create a synonym file to sent to solr"
    task :get_synonyms  => :environment do
      timed_action "get tree" do
        FILE = ENV["FILE"]
        subjects = SubjectMeshEntry.all
        File.new(File.join(Rails.root, FILE), "w") do |sym_file|
          subjects.each do |subject|
            tmp_arr= []
            tmp_arr << subject.term
            tmp_arr += subject.subject_mesh_synonyms.map {|syn|
              syn.subject_synonym
            }
            # escape all the commas!
            tmp_arr.map! { |syn| syn.gsub(/,/, '\,') }
            sym_file.write(tmp_arr.join(','))
            sym_file.write("\n")
          end
        end
      end
    end
  end

  namespace :migrate do
    desc "Convert Batch objects to Collection objects"
    task :batch_to_collection => :environment do
      timed_action "batch to collection migration" do
        a = BatchToCollection.new
        a.migrate
      end
    end

    desc "Add uid info to each User in the database"
    task :users_to_uid => :environment do
      start_time = Time.now
      puts "Starting add uid info at #{start_time}"
      a = AddUidToUsers.new
      a.migrate
      end_time = Time.now
      time_taken = end_time - start_time
      puts "Completed add uid info at #{end_time}, Duration: #{time_taken.inspect}"
    end
  end


  # don't define the ci stuff in production...since rspec is not available
  if defined?(RSpec)
    namespace :jetty do
      JETTY_URL = 'https://github.com/ndlib/hydra-jetty/archive/xacml-updates-for-curate.zip'
      JETTY_ZIP = File.join 'tmp', JETTY_URL.split('/').last
      JETTY_DIR = 'jetty'

      desc "download the jetty zip file"
      task :download do
        puts "Downloading jetty..."
        # system "cp -rf /Users/jfriesen/Repositories/hydra-jetty #{Rails.root.join(JETTY_DIR)}"
        system "curl -L #{JETTY_URL} -o #{JETTY_ZIP}"
        abort "Unable to download jetty from #{JETTY_URL}" unless $?.success?
      end

      task :unzip do
        # Rake::Task["jetty:download"].invoke unless File.exists? JETTY_ZIP
        puts "Unpacking jetty..."
        tmp_save_dir = File.join 'tmp', 'jetty_generator'
        system "unzip -d #{tmp_save_dir} -qo #{JETTY_ZIP}"
        abort "Unable to unzip #{JETTY_ZIP} into tmp_save_dir/" unless $?.success?

        expanded_dir = Dir[File.join(tmp_save_dir, "hydra-jetty-*")].first
        system "mv #{expanded_dir} #{JETTY_DIR}"
        abort "Unable to move #{expanded_dir} into #{JETTY_DIR}/" unless $?.success?
      end

      task :clean do
        system "rm -rf #{JETTY_DIR}"
      end

      task :configure_solr do
        cp('solr_conf/solr.xml', File.join(JETTY_DIR, 'solr/development-core'), verbose: true)
        cp('solr_conf/solr.xml', File.join(JETTY_DIR, 'solr/test-core/'), verbose: true)
        FileList['solr_conf/conf/*'].each do |f|
          cp("#{f}", File.join(JETTY_DIR, 'solr/development-core/conf/'), :verbose => true)
          cp("#{f}", File.join(JETTY_DIR, 'solr/test-core/conf/'), :verbose => true)
        end
      end

      task :configure_fedora do
        cp('fedora_conf/conf/development/fedora.fcfg', File.join(JETTY_DIR, 'fedora/default/server/config/'), verbose: true)
        cp('fedora_conf/conf/test/fedora.fcfg', File.join(JETTY_DIR, 'fedora/test/server/config/'), verbose: true)
      end

    end

    desc 'Run specs on travis'
    task :travis do
      ENV['RAILS_ENV'] = 'ci'
      Rails.env = 'ci'
      Rake::Task['environment'].invoke
      Rake::Task['vecnet:jetty:download'].invoke
      Rake::Task['vecnet:jetty:clean'].invoke
      Rake::Task['vecnet:jetty:unzip'].invoke
      Rake::Task['vecnet:jetty:configure_solr'].invoke
      Rake::Task['vecnet:jetty:configure_fedora'].invoke

      jetty_params = Jettywrapper.load_config
      error = Jettywrapper.wrap(jetty_params) do
        ENV['COVERAGE'] = 'true'
        Rake::Task['vecnet:ci'].invoke
      end
      raise "test failures: #{error}" if error
    end


    desc "Execute Continuous Integration build (docs, tests with coverage)"
    task :ci do
      ENV['RAILS_ENV'] = 'ci'
      Rails.env = 'ci'
      Rake::Task['environment'].invoke
      #Rake::Task["hyhead:doc"].invoke
      #Rake::Task["jetty:config"].invoke
      #Rake::Task["db:drop"].invoke
      #Rake::Task["db:create"].invoke
      Rake::Task['db:schema:load'].invoke

      Rake::Task['vecnet:ci_spec'].invoke
      # I don't think we have any cucumber tests ATM
      #Rake::Task['cucumber'].invoke
    end

    RSpec::Core::RakeTask.new(:ci_spec) do |t|
      t.pattern = "./spec/**/*_spec.rb"
      t.rspec_opts = ['--tag ~js:true']
    end
  end

end
