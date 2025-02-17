class RemoveAccountPlanIdFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :account_plan_id
  end
end
