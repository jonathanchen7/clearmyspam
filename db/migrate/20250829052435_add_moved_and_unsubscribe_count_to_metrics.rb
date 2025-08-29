class AddMovedAndUnsubscribeCountToMetrics < ActiveRecord::Migration[8.0]
  def change
    add_column :metrics, :moved_count, :integer, default: 0, null: false
    add_column :metrics, :unsubscribe_count, :integer, default: 0, null: false
  end
end
