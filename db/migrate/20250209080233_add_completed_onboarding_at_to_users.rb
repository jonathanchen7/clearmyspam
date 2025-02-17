class AddCompletedOnboardingAtToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :onboarding_completed_at, :datetime
  end
end
