class MeshTreeStructure < ActiveRecord::Base
  belongs_to :subject_mesh_entry
  attr_accessible :subject_mesh_term_id, :tree_structure, :eval_tree_path
end