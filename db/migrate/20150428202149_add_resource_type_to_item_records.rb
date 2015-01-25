class AddResourceTypeToItemRecords < ActiveRecord::Migration
  def change
    add_column :item_records, "resource_type", :string, {null: true, default: nil}
    add_column :item_records, "record_mod_date", :datetime
  end
end
