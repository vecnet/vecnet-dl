class LocationHierarchyServices
  attr_accessor :file, :earth
  def initialize(file="/Users/blakshmi/projects/vecnet/lib/geoname_tree.txt")
    @file = file
    @earth='6295630'
  end

  def process_all_geoname_hierachy
    puts @file.inspect
    File.open(@file) do |f|
      f.each_line do |line|
        tmp=line.split('|')
        begin
          geoname_id=tmp.first
          trees=tmp-[geoname_id]
          puts "Processing tree: #{trees.inspect}"
          trees.each { |tree|
            if tree.split('.').include?(@earth)
              GeonameHierarchy.create!( :geonameid => geoname_id,
                                      :hierarchytree => tree,
                                      :hierarchytreetopnoamy=>eval_tree(tree)
              )
            else
              GeonameHierarchy.create!( :geonameid => geoname_id)
            end
          }
        rescue Exception => e
          puts e.inspect
        end
      end
    end
  end

  def eval_tree(tree)
    geoname_ids=tree.split('.')
    geoasciinames=[]
    geoname_ids.each do |id|
      geoasciinames<<Geoname.find(id).asciiname
    end
    return geoasciinames.join(';')
  end

  def resolve_names(geoname_id)
    GeonameHierarchy.create!( :geoname_id => geoname_id,
                              :name => Geoname.find(geoname_id).name,
                              :countryname=>eval_country_name(geoname_id),
                              :admin1name=>eval_admin1_name(geoname_id)
    )

  end

  def self.find_hierarchy(geo_name_id)
    tree_id, tree_names= Geonames::Hierarchy.hierarchy(geo_name_id)
    puts "tree: #{tree_id}, Names:#{tree_names}"
    GeonameHierarchy.find_or_create(geo_name_id,tree_id, tree_names)
    return tree_id, tree_names

  end

  def self.get_geoname_ids(locations)
    geonames_ids={}
    puts "Locations for parse and find gid: #{locations.inspect}"
    unless locations.blank?
      locations.each do |location|
        q = location.split(",").first
        puts "trying to find: #{q.inspect}"
        hits = Geonames::Search.search(q)
        puts "hits: #{hits.inspect}"
        hits.each do |result|
          if result[:label].gsub(/[\s,]/,'').eql?(location.gsub(/[\s,]/,''))
            key=result[:label]
            geoname_id = result[:value]
            puts geoname_id.inspect
            geonames_ids[location]=geoname_id
            break
          end
        end
      end
    end
      puts "hash_of_locations: #{geonames_ids.inspect}"
    return geonames_ids
  end

  def self.get_solr_hierarchy_from_tree(tree)
    hierarchies = [];
    depth = tree.split(":").count-1
    current_hierarchy = tree;
    loop do
      #puts "Depth: #{depth.inspect}, Push: #{current_hierarchy.inspect}"
      hierarchies << "#{current_hierarchy}"
      current_hierarchy = current_hierarchy.rpartition(':').first
      depth= depth.to_i-1
      break if current_hierarchy.empty?
    end
    return hierarchies.reverse;
  end

end
