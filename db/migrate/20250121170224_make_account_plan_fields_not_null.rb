class MakeAccountPlanFieldsNotNull < ActiveRecord::Migration[7.2]
  def change
    change_column_null :account_plans, :user_id, false
    change_column_null :account_plans, :type, false
    rename_column :account_plans, :type, :plan_type
  end
end
