class CreateGeonamehierarchy < ActiveRecord::Migration
  def up
    create_table "geoname_hierarchy", :force => true do |t|
      t.integer "geoname_id", :foreign_key => true
      t.string  "hierarchy_tree",         :limit => 1000
      t.string  "hierarchy_tree_name", :limit => 8000
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false
    end
    add_index "geoname_hierarchy", ["geoname_id", "hierarchy_tree"], :name => "geonamehierarchy_tree_idx", :unique => true
    add_index "geoname_hierarchy", ["geoname_id"], :name => "geonamehierarchy_geonameid_idx"
  end

  def down
    drop_table :geonamehierarchy
    remove_index :geonamehierarchy_tree_idx
    remove_index  :geonamehierarchy_geonameid_idx
  end
end
