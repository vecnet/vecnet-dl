#
# Tasks copied from to CurateND
#
require 'rake'
require 'fileutils'
require 'logger'
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

  #def logger
  #  log = Logger.new('log/EndNoteIngester.log')
  #end

  def location_consolidation_csv
    files = GenericFile.find_with_conditions({},{:sort=>'pub_date desc', :rows=>1000, :fl=>'id,  desc_metadata__based_near_display, location_hierarchy_facet'})
    puts "Total records found: #{files.count}"
    filename = "locations.csv"
    CSV.open("#{Rails.root.to_s}/tmp/#{filename}", "wb") do |csv| #creates a tempfile csv
      files.each do |c|
        puts "Location available: #{c.has_key?('desc_metadata__based_near_display')}"
        if c.has_key?('desc_metadata__based_near_display')
          csv << [c['id'],c['desc_metadata__based_near_display'],c['location_hierarchy_facet']].flatten
        end
      end
    end
  end

  def solrize_location_hierarchy
    files = GenericFile.find_with_conditions({},{:sort=>'pub_date desc', :rows=>1000, :fl=>'id,  desc_metadata__based_near_display, location_hierarchy_facet'})
    i=0
    files.each do |c|
      if (c.has_key?('desc_metadata__based_near_display'))
        pid=c['id']
        puts "indexing #{pid.inspect}"
        solrizer = Solrizer::Fedora::Solrizer.new :index_full_text=> false
        solrizer.solrize(pid, :suppress_errors=>false)
        puts "Finished shelving #{pid}"
        i+=1
      end
    end
    puts "Finished shelving #{i} records"
  end


  def citation_metadata_csv
    citations = Citation.find_with_conditions({},{:sort=>'pub_date desc', :rows=>500, :fl=>'id,  desc_metadata__title_display, desc_metadata__date_created_display'})
    puts "Total records found: #{citations.count}"
    @filename = "citation.csv"
    CSV.open("#{Rails.root.to_s}/tmp/#{@filename}", "wb") do |csv| #creates a tempfile csv
       citations.each do |c|
        csv << [c['id'],c['desc_metadata__title_display'],c['desc_metadata__date_created_display']].flatten
      end
    end
    puts "Now find all id that have more than one title"
    @filename = "citation_non_unique_title.csv"
    CSV.open("#{Rails.root.to_s}/tmp/#{@filename}", "wb") do |csv| #creates a tempfile csv
      csv << ["pid", "title"] #creates the header
      citations.each do |c|
        if c['desc_metadata__title_display'].count>1
          c['desc_metadata__title_display'].each { |title|
            csv << [c['id'], title ]
          }
        end
      end
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


  namespace :destroy do
    desc "Remove all citations in giving environment"
    task :citation => :environment do
      timed_action "destroy citations" do
        Citation.find(:all).each{|c| c.destroy}
      end
    end
  end

  namespace :location do
    desc "Load Hierarchy to table"
    task :trees => :environment do
      timed_action "location hierarchy" do
       LocationHierarchyServices.new().process_all_geoname_hierachy
      end
    end
    desc "get locations for generic files from solr"
    task :get_locations => :environment do
      timed_action "get_locations" do
        location_consolidation_csv
      end
    end

    desc "Solrize location hierarchy"
    task :solrize_location_hierarchy => :environment do
      timed_action "solrize_location_hierarchy" do
        solrize_location_hierarchy
      end
    end
  end

  namespace :citation do
    desc "Reformat all citations bio in giving environment"
    task :reformat_all_bib => :environment do
      timed_action "reformat bibliographic citations" do
        Citation.find(:all).each do |c|
          c.update_citation
        end
      end
    end
    desc "Reformat citation  for given id giving environment"
    task :reformat_citation_with_id => :environment do
      if ENV['PID'].nil?
        raise "You must provide a PID to reformat."
      end
      timed_action "reformat bibliographic citations" do
        c = ActiveFedora::Base.find(ENV['PID'], cast:true)
        bib_format = c.reformat_bibliographic_citation.blank? ? "No bib available" : c.reformat_bibliographic_citation
        puts bib_format
        c.update_citation
      end
    end
    desc "get all citations from solr"
    task :get_citations_from_solr => :environment do
      timed_action "getting all citation data in csv" do
        citation_metadata_csv
      end
    end

    desc "Updating citations to Article resource type"
    task :update_type_to_article => :environment do
      timed_action "update_type_to_article" do
        Citation.find(:all).each do |c|
          c.update_citation_resource_type
        end
      end
    end

    desc "updating all full text for vecnet only users"
    task :update_visibility_to_authenticated => :environment do
      timed_action "update_visibility_to_authenticated" do
        CitationFile.find(:all).each do |c|
          c.update_visibility_as_authenticated
        end
      end
    end

    desc "Update resource type of citation for given id"
    task :update_type_to_article_with_id => :environment do
      if ENV['PID'].nil?
        raise "You must provide a PID to update."
      end
      timed_action "update_type_to_article_with_id" do
        c = ActiveFedora::Base.find(ENV['PID'], cast:true)
        puts c.resource_type
        c.update_citation_resource_type
      end
    end

    desc "update visibilty for given id"
    task :update_visibility_to_authenticated_with_id => :environment do
      if ENV['PID'].nil?
        raise "You must provide a PID to update."
      end
      timed_action "update_visibility_to_authenticated_with_id" do
        c = ActiveFedora::Base.find(ENV['PID'], cast:true)
        puts c.permissions
        c.update_visibility_as_authenticated
      end
    end

  end

  namespace :import do
    def mesh_files
      files=[]
      files<< File.expand_path("#{Rails.root}/mesh-d2013.txt")
    end
    desc "Import Mesh Subjects from text file mesh-d2013.txt"
    task :mesh_subjects => :environment do
      timed_action "harvest" do
        LocalAuthority.harvest_more_mesh_ascii("mesh_subject_harvest",mesh_files)
      end
    end
    task :one_time_mesh_print_entry_import => :environment do
      timed_action "harvest print entry" do
        LocalAuthority.harvest_more_mesh_print_synonyms("mesh_subject_harvest",mesh_files)
      end
    end

    desc "Resolve Mesh Tree Structure"
    task :eval_mesh_trees  => :environment do
      timed_action "eval tree" do
        MeshTreeStructure.classify_all_trees
      end
    end

    desc %q{import endnote file into repository. Environment vars:
    ENDNOTE_FILE - the endnote file to ingest
    ENDNOTE_PDF_PATH - colon seperated list of paths to search for pdf files}
    task :endnote_conversion => :environment do
      if ENV['ENDNOTE_FILE'].nil?
        puts "You must provide a endnote file using the format 'import::endnote_conversion ENDNOTE_FILE=path/to/endnote/file ENDNOTE_PDF_PATH=path/to/find/pdf/files'."
        return
      end
      if ENV['ENDNOTE_PDF_PATH'].nil?
        puts "You must provide a endnote pdf path using the format 'import::endnote_conversion ENDNOTE_FILE=path/to/endnote/file ENDNOTE_PDF_PATH=path/to/find/pdf/files'."
        return
      end
      temp_path = "#{Rails.root}/tmp/citations"
      pdf_paths = ENV['ENDNOTE_PDF_PATH'].split(':')
      #|| ["/Users/blakshmi/projects/endnote"]
      FileUtils.mkdir_p temp_path
      error_list = []
      timed_action "endnote_conversion" do
        current_number = 1
        EndnoteConversionService.each_record(ENV['ENDNOTE_FILE']) do |record|
          begin
            logger.info "#{current_number}) Ingesting"
            logger.info("#{current_number} Ingesting")
            end_filename = "#{temp_path}/#{current_number}.end"
            mods_filename = "#{temp_path}/#{current_number}.mods"
            File.open(end_filename, 'w') { |f| f.write(record) }
            endnote_conversion = EndnoteConversionService.new(end_filename, mods_filename)
            endnote_conversion.convert_to_mods
            File.open(end_filename, 'w') { |f| f.write(record) }
            service = CitationIngestService.new(mods_filename, pdf_paths)
            noid=service.ingest_citation
            current_number+=1
          rescue => e
            message= "#{e.class}: #{e.message}"
            logger.error "Error Occurred: #{message}"
            e.backtrace.each{|error|
              logger.error error.inspect
            }
            error_list << [{current_number => "#{current_number} failed with error.new Could not ingest for the following reasons: #{message}"}]
          end
        end
        puts "Total Errors: #{error_list.length} Errors"
        error_list.each{|error|
          logger.error error.inspect
        }

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


  namespace :db do
    def pg_dump_file_path
      File.expand_path("#{Rails.root}/tmp/production_data.sql")
    end
    desc "Load data from the production database into the current environment"
    task :sync => :environment do
      Rake::Task['app:restrict_from_production'].invoke
      Rake::Task['db:download_pg_dump'].invoke
      if Rails.env == 'development'
        Rake::Task['db:optimze_pg_dump_for_sqlite'].invoke
        Rake::Task['db:recreate_with_dump'].invoke
      else
        `PGPASSWORD=#{current_db['password']} pg_restore --verbose --clean --no-acl --no-owner -h #{current_db['host']} -U #{current_db['username']} -d #{current_db['database']} #{sql_dump}`
      end

    end
    desc 'download the pg_dump content into tmp/dump.sql'
    task :download_pg_dump do
      config = Rails.application.config.database_configuration

      abort "Missing production database config" if config['dlvecnet'].blank?

      dev_config = config['development']
      prod_config = config['dlvecnet']
      abort "Development db is not sqlite3" unless dev_config['adapter'] =~ /sqlite3/
      abort "Production db is not postgresql" unless prod_config['adapter'] =~ /postgresql/
      abort "Missing ssh host" if prod_config['ssh_host'].blank?
      abort "Missing database name" if prod_config['database'].blank?

      # remove the old one
      if File.exists?(pg_dump_file_path)
        File.delete(pg_dump_file_path)
      end

      cmd = "ssh -C "
      cmd << "#{prod_config['ssh_user']}@" if prod_config['ssh_user'].present?
      cmd << "#{prod_config['ssh_host']} "
      cmd << "PGPASSWORD=#{prod_config['password']} "
      cmd << "pg_dump --data-only --inserts "
      cmd << "--username=#{prod_config['username']} #{prod_config['database']} > "
      cmd << pg_dump_file_path
      puts "Exceute #{cmd}"
      system `#{cmd}`
    end

    desc 'remove unused statements and optimze sql for SQLite'
    task :optimze_pg_dump_for_sqlite do
      result = []
      lines = File.readlines(pg_dump_file_path)
      @version = 0
      lines.each do | line |
        next if line =~ /SELECT pg_catalog.setval/ # sequence value's
        next if line =~ /SET / # postgres specific config

        if line =~ /INSERT INTO schema_migrations/
          @version = line.match(/INSERT INTO schema_migrations VALUES \('([\d]*)/)[1]
          puts("Version: #{@version}")
        end

        # replace true and false for 't' and 'f'
        line.gsub!("true","'t'")
        line.gsub!("false","'f'")
        result << line
      end

      File.open(pg_dump_file_path, "w") do |f|
        # Add BEGIN and END so we add it to 1 transaction. Increase speed!
        f.puts("BEGIN;")
        result.each{|line| f.puts(line) unless line.blank?}
        f.puts("END;")
      end
    end

    desc 'backup development.sqlite3 and create a new one with the dumped data'
    task :recreate_with_dump do
      # sqlite so backup
      database = Rails.configuration.database_configuration['development']['database']
      database_path = File.expand_path("#{Rails.root}/#{database}")
      # remove old backup
      if File.exists?(database_path + '.backup')
        File.delete(database_path + '.backup')
      end
      # copy current for backup
      FileUtils.cp database_path, database_path + '.backup' if File.exists?(database_path)

      # dropping and re-creating db
      ENV['VERSION'] = @version
      Rake::Task['db:drop'].invoke
      Rake::Task["db:migrate"].invoke

      puts "migrated to version: #{@version}"
      puts "importing..."
      # remove migration info
      system `sqlite3 #{database_path} "delete from schema_migrations;"`
      # import dump.sql
      system `sqlite3 #{database_path} ".read #{pg_dump_file_path}"`

      puts "DONE!"
      puts "NOTE: you're now migrated to version #{@version}. Please run db:migrate to apply newer migrations"
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
