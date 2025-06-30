class DropEmailThreads < ActiveRecord::Migration[8.0]
  def change
    drop_table :email_threads
  end
end
