class RenameEmailThreadDeletedToTrashed < ActiveRecord::Migration[7.2]
  def change
    rename_column :email_threads, :deleted, :trashed
  end
end
