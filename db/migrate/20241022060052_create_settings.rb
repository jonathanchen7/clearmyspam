class CreateSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :settings, id: :uuid do |t|
      t.boolean :hide_personal_emails
      t.uuid :user_id
      t.boolean :archive_email_threads
      t.boolean :unread_only

      t.timestamps
    end
  end
end
