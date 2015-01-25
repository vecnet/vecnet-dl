class CreateItemRecords < ActiveRecord::Migration
  def change
    create_table :item_records do |t|
      t.string    :pid, length: 30, null: false, unique: true
      t.string    :af_model
      t.string    :owner
      t.integer   :bytes
      t.string    :mimetype
      t.string    :parent
      t.string    :aggregation_key
      t.datetime  :ingest_date
      t.datetime  :modified_date
      t.string    :access_rights
    end
    primary_key(:item_records, :pid)
  end
end
