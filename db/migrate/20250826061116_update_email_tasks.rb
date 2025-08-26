class UpdateEmailTasks < ActiveRecord::Migration[8.0]
  def change
    rename_column :email_tasks, :type, :task_type
  end
end
