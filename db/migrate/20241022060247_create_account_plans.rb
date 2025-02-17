class CreateAccountPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :account_plans, id: :uuid do |t|
      t.string :type
      t.uuid :user_id
      t.string :stripe_subscription_id
      t.string :stripe_customer_id
      t.timestamp :stripe_subscription_ended_at
      t.integer :thread_limit

      t.timestamps
    end
  end
end
