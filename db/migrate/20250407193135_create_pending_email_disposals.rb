class CreatePendingEmailDisposals < ActiveRecord::Migration[8.0]
  def change
    create_table :pending_email_disposals, id: :uuid do |t|
      t.uuid :email_thread_id, null: false
      t.uuid :user_id, null: false
      t.string :vendor_id, null: false
      t.boolean :archive, null: false
      t.datetime :created_at, null: false

      t.index [:user_id, :created_at]
      t.index [:user_id, :vendor_id], unique: true
    end
  end
end
