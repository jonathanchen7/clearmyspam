class CreateProtectedEmailsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :protected_emails, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :vendor_id, null: false
      t.timestamps

      t.index %i[user_id vendor_id], unique: true
    end
  end
end
