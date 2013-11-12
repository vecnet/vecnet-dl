module Vecnet
  module ModelMethods
    extend ActiveSupport::Concern
=begin
    def locations(locations=nil)
      locations=locations
      new_locations=locations.map{|loc| refactor_location(loc) }
      new_locations
    end

    def refactor_location(location)
      return location.split(',').each_with_object([]) {|name, a| a<< name.strip unless name.to_s.strip.empty?}.uniq.join(',')
    end
=end

    def get_hierarchy_on_location(locations=nil)
      unless locations.blank?
        geoname_id_hash= LocationHierarchyServices.get_geoname_ids(locations)
        location_trees=[]
        location_tree_to_solrize=[]
        geoname_id_hash.each do |location,geoname_id|
          hierarchy= GeonameHierarchy.find_by_geoname_id(geoname_id)
          hierarchy_with_earth=''
          if hierarchy && hierarchy.hierarchy_tree_name.present?
            hierarchy_with_earth= hierarchy.hierarchy_tree_name.gsub(';',':')
          else
            tree_id, tree_name = LocationHierarchyServices.find_hierarchy(geoname_id)
            hierarchy_with_earth=tree_name.gsub(';',':')
          end
          hierarchy_without_earth=hierarchy_with_earth.gsub('Earth:','')
          location_tree_to_solrize<<hierarchy_without_earth
        end
        location_trees<<location_tree_to_solrize.collect{|tree| LocationHierarchyServices.get_solr_hierarchy_from_tree(tree)}.flatten
        return location_trees.flatten
      end
      return nil
    end

    def get_formated_date_created(create_date=nil)
      return nil if create_date.blank?
      return @pub_date_sort.to_time.utc.iso8601 unless @pub_date_sort.nil?
      pub_date=create_date.first
      if create_date.size>1
        logger.error "#{self.pid} has more than one pub date, #{create_date.inspect}, but will only use #{pub_date} for sorting"
      end
      pub_date_replace=pub_date.gsub(/-|\/|,|\s/, '.')
      @pub_date_sort=pub_date_replace.split('.').size> 1? Chronic.parse(pub_date) : Date.strptime(pub_date,'%Y')
      return @pub_date_sort.to_time.utc.iso8601 unless @pub_date_sort.blank?
    end

    def get_subject_parents(subjects)
      subjects=subjects
      all_trees_arr=[]
      subjects.each do |sub|
        mesh_subject= SubjectMeshEntry.find_by_term(sub)
        if mesh_subject
          all_trees_arr<<mesh_subject.mesh_tree_structures.collect{|tree| tree.get_solr_hierarchy_from_tree}.flatten
        end
      end
      return all_trees_arr.uniq
    end

    def get_hierarchical_faceting_on_subject(subjects)
      subjects=subjects
      all_trees=[]
      subjects.each do |sub|
        mesh_subject= SubjectMeshEntry.find_by_term(sub)
        if mesh_subject
          all_trees<<mesh_subject.mesh_tree_structures.collect{|tree| tree.get_solr_hierarchy_from_tree}.flatten
        end
      end
      return all_trees.flatten
    end

    def get_hierarchical_faceting_on_species(species=self.species)
      all_trees=[]
      species.each do |specie|
        ncbi_specie= NcbiSpeciesTerm.find_by_term(specie)
        if ncbi_specie
          all_trees<<ncbi_specie.get_solr_hierarchy_from_tree.flatten
        end
      end
      return all_trees.flatten
    end
  end
end
