class AddUserIdIndexesToTables < ActiveRecord::Migration[7.2]
  def change
    add_index :email_threads, :user_id
    add_index :options, :user_id
    add_index :account_plans, :user_id
  end
end
