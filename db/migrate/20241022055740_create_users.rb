class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: :uuid do |t|
      t.string :name
      t.string :email
      t.uuid :account_plan_id
      t.string :google_refresh_token
      t.string :picture

      t.timestamps
    end
  end
end
