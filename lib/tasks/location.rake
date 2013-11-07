namespace :vecnet do
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
  end
end
