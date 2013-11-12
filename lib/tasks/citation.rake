
namespace :vecnet do
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
    desc "Copy Subject Species to Species metadata"
    task :one_time_species_copy => :environment do
      timed_action "copy species from subject" do
        Citation.find(:all).each do |c|
          c.assign_species_from_subject
          logger.info("\t ############ Species to save: #{g.species.inspect}, Citation id:#{g.id} ")
          c.update_citation unless c.species.blank?
        end
        GenericFile.find(:all).each do |g|
          g.assign_species_from_subject
          logger.info("\t ############ Species to save: #{g.species.inspect}, GenericFile id:#{g.id} ")
          g.save unless g.species.blank?
        end
      end
    end

    desc "Remove all Species from Species metadata"
    task :one_time_species_delete => :environment do
      timed_action "removing species from citations" do
        Citation.find(:all).each do |c|
          c.species=[]
          c.save
        end
      end
    end

    desc "Copy Subject Species to Species metadata for given PID"
    task :species_copy_for_given_pid => :environment do
      if ENV['PID'].nil?
        raise "You must provide a PID to copy."
      end
      timed_action "copy species from subject" do
        c = ActiveFedora::Base.find(ENV['PID'], cast:true)
        c.copy_species_from_subject
        puts "Species to save: #{c.species.inspect}"
        c.update_citation unless c.species.blank?
      end
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

    desc "update citations with metadata from csv"
    task :enrich_metadata => :environment do
      timed_action "update citation with metadata from csv" do
        if ENV['CITATION_CSV_FILE'].nil?
          puts "You must provide a csv file with metadata using the format 'vecnet::citation::enrich_metadata CITATION_CSV_FILE=path/to/citation/csv/file."
          return
        end
        citation_metadata_update = CitationMetadataUpdateService.new(ENV['CITATION_CSV_FILE'])
        citation_metadata_update.ingest_all
      end
    end

  end
end
