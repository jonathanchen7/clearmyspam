class CreateEmailThreads < ActiveRecord::Migration[7.2]
  def change
    create_table :email_threads, id: :uuid do |t|
      t.string :vendor_id
      t.boolean :protected
      t.uuid :user_id
      t.boolean :deleted
      t.boolean :archived

      t.timestamps
    end
  end
end
