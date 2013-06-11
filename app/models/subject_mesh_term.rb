class SubjectMeshTerm < ActiveRecord::Base
  belongs_to :subject_mesh_entry
  attr_accessible :term, :subject_mesh_term_id
end