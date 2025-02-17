class UpdateOptionDefaults < ActiveRecord::Migration[7.2]
  def change
    change_column_default :options, :archive_email_threads, from: nil, to: false
    change_column_default :options, :hide_personal_emails, from: nil, to: false
    change_column_default :options, :unread_only, from: nil, to: true

    change_column_null :options, :archive_email_threads, false
    change_column_null :options, :hide_personal_emails, false
    change_column_null :options, :unread_only, false
  end
end
