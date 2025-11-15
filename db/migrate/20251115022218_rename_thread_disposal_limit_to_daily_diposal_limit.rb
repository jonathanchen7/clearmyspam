class RenameThreadDisposalLimitToDailyDiposalLimit < ActiveRecord::Migration[8.1]
  def change
    rename_column :account_plans, :thread_disposal_limit, :daily_disposal_limit
  end
end
