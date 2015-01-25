class AddMoreInfoToUsageEvents < ActiveRecord::Migration
  def change
    add_column :usage_events, "parent_pid", :string, {limit: 30, null: true, default: nil}
    add_column :usage_events, "event_time", :datetime
    # rename since "type" conflicts with an activerecord reserved column name
    rename_column :usage_events, "type", "event"
  end
end
