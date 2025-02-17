class AddConstraintsToEmailThreads < ActiveRecord::Migration[7.2]
  def change
    change_column_null :email_threads, :archived, false
    change_column_null :email_threads, :deleted, false
    change_column_null :email_threads, :protected, false
    change_column_null :email_threads, :user_id, false
    change_column_null :email_threads, :vendor_id, false

    change_column_default :email_threads, :archived, from: nil, to: false
    change_column_default :email_threads, :deleted, from: nil, to: false
    change_column_default :email_threads, :protected, from: nil, to: false

    add_index :email_threads, :vendor_id, unique: true
  end
end
