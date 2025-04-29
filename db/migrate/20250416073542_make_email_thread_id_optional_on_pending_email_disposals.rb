# frozen_string_literal: true

class MakeEmailThreadIdOptionalOnPendingEmailDisposals < ActiveRecord::Migration[7.1]
  def change
    change_column_null :pending_email_disposals, :email_thread_id, true
  end
end
