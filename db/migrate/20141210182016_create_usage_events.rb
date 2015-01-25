class CreateUsageEvents < ActiveRecord::Migration
  def change
    create_table :usage_events do |t|
      t.string :type,       length: 30, null: false
      t.string :pid,        length: 30, null: false, index: true
      t.string :ip_address, length: 64
      t.string :username,               null: true, index: true

      t.timestamps
    end
  end
end
