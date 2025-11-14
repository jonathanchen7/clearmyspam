class CreateSentEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :sent_emails, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.string :email_type, null: false
      t.jsonb :metadata_json, null: false, default: {}
      t.datetime :sent_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps

      t.index [:user_id, :email_type], unique: true
    end
  end
end
