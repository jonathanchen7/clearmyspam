class AddMetricsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :metrics, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.integer :initial_total_threads, null: false
      t.integer :initial_unread_threads, null: false
      t.integer :total_threads, null: false
      t.integer :unread_threads, null: false
      t.integer :trashed_count, default: 0, null: false
      t.integer :archived_count, default: 0, null: false
      t.timestamps

      t.index %i[user_id], unique: true
    end
  end
end