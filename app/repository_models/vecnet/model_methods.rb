module Vecnet
  module ModelMethods
    extend ActiveSupport::Concern

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

    # not sure what the difference between get_subject_parents() and
    # get_hierarchical_faceting_on_subject() is
    def get_subject_parents(subjects)
      subject_trees(subjects).uniq
    end

    def get_hierarchical_faceting_on_subject(subjects)
      subject_trees(subjects).flatten
    end

    def subject_trees(subjects)
      all_trees = []
      subjects.each do |sub|
        mesh_subject = SubjectMeshEntry.find_by_term(sub)
        if mesh_subject
          all_trees << mesh_subject.mesh_tree_structures.collect{|tree| tree.get_solr_hierarchy_from_tree}.flatten
        end
      end
      all_trees
    end
  end
end
