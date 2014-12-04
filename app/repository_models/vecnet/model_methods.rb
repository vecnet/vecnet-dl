module Vecnet
  module ModelMethods
    extend ActiveSupport::Concern

    # convert a list of location names into a list of tree fragments used by solr to facet
    # index the place names
    def get_hierarchy_on_location(locations=nil)
      return [] if locations.blank?
      locations.map do |location|
        LocationHierarchyServices.name_to_solr_hierarchy(location)
      end.flatten
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
      all_trees = subjects.map do |sub|
        mesh_subject = SubjectMeshEntry.find_by_term(sub)
        if mesh_subject
          mesh_subject.mesh_tree_structures.map do |tree|
            tree.get_solr_hierarchy_from_tree
          end.flatten
        end
      end
      all_trees.compact.flatten
    end
  end
end
