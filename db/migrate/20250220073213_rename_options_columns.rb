class RenameOptionsColumns < ActiveRecord::Migration[7.2]
  def change
    rename_column :options, :archive_email_threads, :archive
    rename_column :options, :hide_personal_emails, :hide_personal
  end
end
