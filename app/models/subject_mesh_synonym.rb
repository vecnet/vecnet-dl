class SubjectMeshSynonym < ActiveRecord::Base
  belongs_to :subject_mesh_entry
  attr_accessible :subject_synonym, :subject_mesh_term_id
end