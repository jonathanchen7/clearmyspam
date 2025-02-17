class RenameThreadLimitToThreadDisposalLimit < ActiveRecord::Migration[7.2]
  def change
    rename_column :account_plans, :thread_limit, :thread_disposal_limit
  end
end
