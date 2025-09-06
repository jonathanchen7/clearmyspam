class AddSendMarketingEmailsToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :send_marketing_emails, :boolean, default: true
  end
end
