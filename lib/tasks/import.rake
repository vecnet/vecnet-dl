require 'ncbi_tools'
require 'benchmark'

namespace :vecnet do
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
    desc "task to process mods file and print metadata into csv"
    task :display_new_bib => :environment do
      timed_action "Show new bib format for citations" do
        end_note_path = "#{Rails.root}/tmp/citations"
        current_number = 0
        filename = "bib.csv"
        CSV.open("#{Rails.root.to_s}/tmp/#{filename}", "wb") do |csv|
          Dir.glob("#{end_note_path}/*.mods") do |mods_file|
            puts "Process file #{mods_file.inspect}"
            # do work on files ending in .mods in the desired directory
            service = CitationIngestService.new(mods_file)
            bib=service.extract_metadata
            csv << [bib]
            current_number+=1
          end
        end
        puts "processed #{current_number} files"
      end
    end

    #
    # NCBI Taxonomy terms
    #

    desc "import taxonomy terms from NCBI dump files"
    task :ncbi_taxonomy do
      # invoke the tasks explicitly (as opposed to listing them as
      # prerequisites), since we want them done in the given order
      Rake::Task["vecnet:import:ncbi_import_terms"].invoke
      Rake::Task["vecnet:import:ncbi_generate_facet_tree"].invoke
    end

    task :ncbi_import_terms => [:environment, :ncbi_generate_files] do
      puts "Importing terms"
      NcbiSpeciesTerm.load_from_tree_file("data/tax-tree.txt")
    end

    task :ncbi_generate_facet_tree => :environment do
      puts "Generating Faceting Tree"
      NcbiSpeciesTerm.generate_facet_treenumbers do |t|
        t.subtree("7157")   # keep Culicidae family
        t.subtree("5820")   # keep Plasmodium genus
        t.remove_rank("subfamily")
        t.remove_rank("subgenus")
        t.remove_rank("tribe")
        t.remove_rank("no rank")
      end
    end

    task :ncbi_generate_files => ['data/tax-tree.txt', 'data/tax-synonyms.txt']

    directory "data"
    directory "data/taxdump"

    file 'data/tax-tree.txt' => ['data/taxdump/nodes.dmp', 'data/taxdump/names.dmp'] do
      puts "Creating Tree File"
      NcbiTools.new.create_tree_file('data/taxdump/nodes.dmp',
                                 'data/taxdump/names.dmp',
                                 'data/tax-tree.txt')
    end
    file 'data/tax-synonyms.txt' => 'data/taxdump/names.dmp' do
      puts "Creating Synonym File"
      NcbiTools.new.create_synonym_file('data/taxdump/names.dmp',
                                    'data/tax-synonyms.txt')
    end
    file 'data/taxdump/names.dmp' => 'data/taxdump/nodes.dmp'
    file "data/taxdump/nodes.dmp" => ["data/taxdump", "data/taxdump.tar.gz"] do
      sh "mkdir -p data/taxdump && tar -x -v -C data/taxdump -m -f data/taxdump.tar.gz"
    end
    file "data/taxdump.tar.gz" => "data" do
      puts "Downloading term file"
      sh "curl -# -o data/taxdump.tar.gz ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz"
    end

    #
    # Citations
    #

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
        current_number = 0
        EndnoteConversionService.each_record(ENV['ENDNOTE_FILE']) do |record|
          begin
            current_number += 1
            logger.info "#{current_number}) Ingesting"
            end_filename = "#{temp_path}/#{current_number}.end"
            mods_filename = "#{temp_path}/#{current_number}.mods"
            File.open(end_filename, 'w') { |f| f.write(record) }
            endnote_conversion = EndnoteConversionService.new(end_filename, mods_filename)
            endnote_conversion.convert_to_mods
            service = CitationIngestService.new(mods_filename, pdf_paths)
            noid = service.ingest_citation
            logger.info "Ingested as #{noid}"
          rescue => e
            message = "#{e.class}: #{e.message}"
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
end
