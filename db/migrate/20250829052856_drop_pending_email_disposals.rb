class DropPendingEmailDisposals < ActiveRecord::Migration[8.0]
  def change
    drop_table :pending_email_disposals
  end
end
