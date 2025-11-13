class UpdateUnsubscribeCountColumns < ActiveRecord::Migration[8.1]
  def change
    rename_column :metrics, :unsubscribe_count, :successful_unsubscribe_count
    add_column :metrics, :failed_unsubscribe_count, :integer, default: 0, null: false

    rename_column :daily_metrics, :unsubscribe_count, :successful_unsubscribe_count
    add_column :daily_metrics, :failed_unsubscribe_count, :integer, default: 0, null: false
  end
end
