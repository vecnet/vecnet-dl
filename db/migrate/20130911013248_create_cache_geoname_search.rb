class CreateCacheGeonameSearch < ActiveRecord::Migration
  def up
    create_table :geoname_search, :force=> true do |t|
      t.integer "geoname_id", :foreign_key => true
      t.string  "geo_location"
      t.string  "object_id"
      t.timestamps
    end
    add_index :geoname_search, [:geoname_id, :object_id], :name => "entries_by_geoname_id_and_object_id", :unique=>true
    add_index :geoname_search, [:geo_location], :name => 'entries_by_geo_location'
  end

  def down
    drop_table :geoname_search
    remove_index :entries_by_geoname_id_and_object_id
    remove_index :entries_by_geo_location
  end
end
