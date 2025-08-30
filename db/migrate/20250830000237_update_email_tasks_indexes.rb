class UpdateEmailTasksIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :email_tasks, [:user_id, :task_type, :vendor_id], unique: true
    remove_index :email_tasks, [:user_id, :vendor_id], unique: true
  end
end
