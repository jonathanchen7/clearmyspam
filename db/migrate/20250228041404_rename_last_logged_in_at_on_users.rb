class RenameLastLoggedInAtOnUsers < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :last_logged_in_at, :last_login_at
  end
end
