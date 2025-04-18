class CreateProtectedSendersTable < ActiveRecord::Migration[8.0]
  def change
    create_table :protected_senders, id: :uuid do |t|
      t.string :sender_id, null: false
      t.uuid :user_id, null: false
      t.timestamps

      t.index %i[sender_id user_id], unique: true
    end
  end
end
