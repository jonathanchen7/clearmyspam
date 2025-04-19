class RemoveEmailThreadIdFromPendingEmailDisposals < ActiveRecord::Migration[8.0]
  def change
    remove_column :pending_email_disposals, :email_thread_id
  end
end
