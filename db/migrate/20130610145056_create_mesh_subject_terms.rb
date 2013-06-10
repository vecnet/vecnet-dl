class CreateMeshSubjectTerms < ActiveRecord::Migration
  def up
    create_table :subject_mesh_term_entries, :force => true  do |t|
      t.string :term
      t.string :lower_term
      t.string :subject_mesh_term_id, :unique=>true
      t.text :subject_synonyms
      t.text :subject_description
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end
    create_table :mesh_tree_structures, :id => false do |t|
      t.string :subject_mesh_term_id, :foreign_key => true
      t.string :tree_structure
      t.string :eval_tree_path
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end
    add_index :subject_mesh_term_entries, [:subject_mesh_term_id], :name => 'entries_by_subject_mesh_term_id'
    add_index :subject_mesh_term_entries, [:subject_mesh_term_id, :term], :name => 'entries_by_id_and_term'
    add_index :mesh_tree_structures, [:subject_mesh_term_id, :tree_structure], :name => 'entries_by_term_id_and_tree_structure'
    add_index :mesh_tree_structures, [:tree_structure], :name => 'entries_by_tree_structure'
  end

  def down
  end
end
