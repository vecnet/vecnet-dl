require 'csv'

namespace :vecnet do
  namespace :citation do

    desc "remove bogus url entries, e.g. <Go to ISI>://"
    task :remove_bogus_urls => :environment do
      timed_action "remove bogus urls" do
        Citation.find_each do |c|
          # c.related_url is a TermProxy and not an array,
          # so it doesn't have #reject.
          new_urls = c.related_url.map do |url|
            url.match(/<go to isi>/i) ? nil : url
          end
          new_urls.compact!
          if new_urls != c.related_url
            puts "Fixing #{c.noid}"
            c.related_url = new_urls
            c.save
          end
        end
      end
    end

    desc "Export Article Visibility to TSV."
    task :export_to_tsv => :environment do
      count = 0
      CSV.open("article-export.tsv", "w", {col_sep: "\t"}) do |csv|
        csv << ["vecnet_id", "title", "journal", "year", "bib_citation", "child_id", "access"]
        Citation.find_each do |citation|
          citation.generic_files.each do |gf|
            count += 1
            puts "#{count}) #{citation.noid} / #{gf.noid}"
            access = "Private"
            if gf.read_groups.include?("public")
              access = "Open Access"
            elsif gf.read_groups.include?("registered")
              access = "VecNet Only"
            end
            csv << [citation.noid,
                    citation.title,
                    citation.source.first,
                    citation.date_created.first,
                    citation.bibliographic_citation.first,
                    gf.noid,
                    access]
          end
        end
      end


      Citation.find_each do |c|
      end
    end


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
        c.save
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
          logger.info("\t ############ Species to save: #{c.species.inspect}, Citation id:#{c.id} ")
          c.save! unless c.species.blank?
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
        c.save unless c.species.blank?
      end
    end

    def citation_metadata_csv
      citations = Citation.find_with_conditions({},{:sort=>'pub_date desc', :rows=>5000, :fl=>'id,  desc_metadata__title_display, desc_metadata__bibliographic_citation_t, desc_metadata__species_t, desc_metadata__source_t'})
      puts "Total records found: #{citations.count}"
      @filename = "citation.csv"
      CSV.open("#{Rails.root.to_s}/tmp/#{@filename}", "wb") do |csv| #creates a tempfile csv
         citations.each do |c|
          csv << [c['id'],c['desc_metadata__source_t'],c['desc_metadata__bibliographic_citation_t']].flatten
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
      species_filename = "citation_with_species.csv"
      CSV.open("#{Rails.root.to_s}/tmp/#{species_filename}", "wb") do |csv| #creates a tempfile csv
        csv << ["pid", "bib", "species"] #creates the header
        citations.each do |c|
          unless c['desc_metadata__species_t'].blank?
            csv << [c['id'],c['desc_metadata__bibliographic_citation_t'], c['desc_metadata__species_t']].flatten
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

    desc "updating bibliographic citations for given citations"
    task :update_citation_bib_record => :environment do
      timed_action "update citation with metadata from csv" do
        if ENV['CITATION_CSV_FILE'].nil?
          puts "You must provide a csv file with metadata using the format 'vecnet::citation::update_citation_bib_record CITATION_CSV_FILE=path/to/citation/csv/file."
          return
        end
        citation_metadata_update = CitationMetadataUpdateService.new(ENV['CITATION_CSV_FILE'])
        citation_metadata_update.update_bib
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
