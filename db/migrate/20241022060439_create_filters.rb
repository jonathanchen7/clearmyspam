class CreateFilters < ActiveRecord::Migration[7.2]
  def change
    create_table :filters, id: :uuid do |t|
      t.string :vendor_id
      t.uuid :user_id

      t.timestamps
    end
  end
end
