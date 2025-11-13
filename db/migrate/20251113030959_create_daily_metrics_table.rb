class CreateDailyMetricsTable < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_metrics, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.date :date, null: false
      t.integer :total_threads, null: false
      t.integer :unread_threads, null: false
      t.integer :archived_count, null: false, default: 0
      t.integer :trashed_count, null: false, default: 0
      t.integer :moved_count, null: false, default: 0
      t.integer :unsubscribe_count, null: false, default: 0
      t.timestamps

      t.index [:user_id, :date], unique: true
    end
  end
end
