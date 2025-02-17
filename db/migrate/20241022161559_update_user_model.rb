class UpdateUserModel < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :vendor_id, :string, null: false
    rename_column :users, :picture, :image
    change_column_null :users, :email, false
    change_column_null :users, :name, false

    add_index :users, :vendor_id, unique: true
  end
end
