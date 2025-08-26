class CreateEmailTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :email_tasks, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :vendor_id, null: false
      t.string :type, null: false
      t.integer :attempts, null: false, default: 0
      t.jsonb :payload, null: true

      t.timestamps

      t.index [:user_id, :vendor_id], unique: true
      t.index [:user_id, :created_at]
    end
  end
end
