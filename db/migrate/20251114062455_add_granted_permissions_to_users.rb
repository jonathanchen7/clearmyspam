class AddGrantedPermissionsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :granted_permissions, :boolean, default: false
  end
end
