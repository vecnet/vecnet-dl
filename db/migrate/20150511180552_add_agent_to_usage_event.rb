class AddAgentToUsageEvent < ActiveRecord::Migration
  def change
    add_column :usage_events, "agent", :string, {null: true, default: nil}
  end
end
