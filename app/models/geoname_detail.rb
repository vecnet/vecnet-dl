class GeonameDetails < ActiveRecord::Base
  self.table_name = 'geonamedetail'
  self.primary_key = 'geonamedetailid'
  belongs_to :geoname , :foreign_key => "geonameid"
  #attr_accessible :subject_mesh_term_id, :tree_structure, :eval_tree_path

  #serialize :eval_tree_path

  #def self.get_country_name(geoname_id)
  #  Conr.where(:subject_mesh_term_id=>
  #                             MeshTreeStructure.where('mesh_tree_structures.tree_structure' => mesh_tree).map(&:subject_mesh_term_id)
  #  )
  #end
  #
  #def self.classify_all_trees
  #  MeshTreeStructure.find_each do |mts|
  #    mts.classify_tree!
  #  end
  #end
  #
  #def eval_tree_path
  #  trees = read_attribute(:eval_tree_path) || write_attribute(:eval_tree_path, "")
  #  if trees
  #    trees.split("|")
  #  else
  #    []
  #  end
  #end
end