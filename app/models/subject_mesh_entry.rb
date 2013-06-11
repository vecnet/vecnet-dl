class SubjectEntry < ActiveRecord::Base
  has_many :mesh_tree_structures
  has_many :subject_mesh_terms
  has_many :subject_mesh_synonyms
  attr_accessible :subject_mesh_term_id, :subject_description

  serialize :subject_description
end