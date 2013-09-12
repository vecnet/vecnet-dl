class CreateGeoname < ActiveRecord::Migration
  def up
    create_table "geoname", :id => false, :force => true do |t|
      t.integer "geonameid",:unique=>true, :primary=>true, :null => false
      t.string  "name",           :limit => 200
      t.string  "asciiname",      :limit => 200
      t.string  "alternatenames", :limit => 8000
      t.float   "latitude"
      t.float   "longitude"
      t.string  "fclass",         :limit => 1
      t.string  "fcode",          :limit => 10
      t.string  "country",        :limit => 2
      t.string  "cc2",            :limit => 60
      t.string  "admin1",         :limit => 20
      t.string  "admin2",         :limit => 80
      t.string  "admin3",         :limit => 20
      t.string  "admin4",         :limit => 20
      t.integer "population",     :limit => 8
      t.integer "elevation"
      t.integer "gtopo30"
      t.string  "timezone",       :limit => 40
      t.date    "moddate"
      t.timestamps
    end

    add_index "geoname", ["geonameid", "name"], :name => "geonamename_idx", :unique => true
    add_index "geoname", ["geonameid"], :name => "geonameid_idx", :unique => true

    execute "ALTER TABLE geoname ADD PRIMARY KEY (geonameid);"
    execute 'ALTER TABLE geoname ALTER COLUMN created_at set default now();'
    execute 'ALTER TABLE geoname ALTER COLUMN updated_at set default now();'
  end

  def down
    drop_table :geoname
    remove_index :geonamename_idx
    remove_index :geonameid_idx
  end
end
