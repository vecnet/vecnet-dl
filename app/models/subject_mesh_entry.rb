class SubjectMeshEntry < ActiveRecord::Base
  has_many :mesh_tree_structures , :foreign_key => "subject_mesh_term_id"
  has_many :subject_mesh_synonyms , :foreign_key => "subject_mesh_term_id"
  attr_accessible :subject_mesh_term_id, :subject_description,:term

  serialize :subject_description

  self.primary_key = 'subject_mesh_term_id'

  def self.trees(tree_id)
    SubjectMeshEntry.joins(:mesh_tree_structures).where('mesh_tree_structures.tree_structure = ?', tree_id)
  end
end