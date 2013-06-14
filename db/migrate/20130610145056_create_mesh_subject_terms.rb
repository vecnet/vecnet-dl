class CreateMeshSubjectTerms < ActiveRecord::Migration
  def up
    create_table :subject_mesh_entries, {:id => false, :force => true}  do |t|
      t.string :subject_mesh_term_id, :unique=>true, :primary=>true
      t.string :term
      t.text :subject_description
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end

    execute "ALTER TABLE subject_mesh_entries ADD PRIMARY KEY (subject_mesh_term_id);"

    create_table :subject_mesh_synonyms, :force => true  do |t|
      t.string :subject_mesh_term_id, :foreign_key=>true
      t.string :subject_synonym
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end
    create_table :mesh_tree_structures, :force=> true do |t|
      t.string :subject_mesh_term_id, :foreign_key => true
      t.string :tree_structure
      t.text :eval_tree_path
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end
    add_index :subject_mesh_entries, [:subject_mesh_term_id], :name => 'entries_by_subject_mesh_term_id'
    add_index :subject_mesh_entries, [:subject_mesh_term_id, :term], :name => 'entries_by_id_and_term', :unique=>true
    add_index :subject_mesh_synonyms, [:subject_mesh_term_id, :subject_synonym], :name => 'entries_by_id_and_synonyms' , :unique=>true
    add_index :mesh_tree_structures, [:subject_mesh_term_id, :tree_structure], :name => 'entries_by_term_id_and_tree_structure', :unique=>true
    add_index :mesh_tree_structures, [:tree_structure], :name => 'entries_by_tree_structure'
  end

  def down
    drop_table :subject_mesh_entries
    drop_table :subject_mesh_synonyms
    drop_table :mesh_tree_structures
    remove_index :subject_mesh_entries, :name => 'entries_by_subject_mesh_term_id'
    remove_index :subject_mesh_entries, :name => 'entries_by_id_and_term'
    remove_index :subject_mesh_synonyms, :name => 'entries_by_id_and_synonyms'
    remove_index :mesh_tree_structures, :name => 'entries_by_term_id_and_tree_structure'
    remove_index :mesh_tree_structures, :name => 'entries_by_tree_structure'
  end
end
