class CreateSpeciesTerms < ActiveRecord::Migration
  def up
    create_table :species_taxon_entries, {:id => false, :force => true}  do |t|
      t.string :species_taxon_id, :unique=>true, :primary=>true
      t.string :term
      t.string :term_type
      t.string :full_tree_id
      t.string :facet_tree_id
      t.string :facet_tree_term
      t.text :term_synonyms
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end

    execute "ALTER TABLE species_taxon_entries ADD PRIMARY KEY (species_taxon_id);"

    add_index :species_taxon_entries, [:species_taxon_id, :term], :name => 'entries_by_species_id_and_term', :unique=>true
    add_index :species_taxon_entries, [:species_taxon_id, :term_synonyms], :name => 'entries_by_species_id_and_synonyms' , :unique=>true
    add_index :species_taxon_entries, [:species_taxon_id, :facet_tree_term], :name => 'entries_by_id_and_tree_term' , :unique=>true
  end

  def down
    drop_table :species_taxon_entries
    remove_index :species_taxon_entries, :name => 'entries_by_species_id'
    remove_index :species_taxon_entries, :name => 'entries_by_species_id_and_term'
    remove_index :species_taxon_entries, :name => 'entries_by_species_id_and_synonyms'
    remove_index :species_taxon_entries, :name => 'entries_by_id_and_tree_term'
  end
end
