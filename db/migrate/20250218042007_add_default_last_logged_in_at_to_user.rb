class AddDefaultLastLoggedInAtToUser < ActiveRecord::Migration[7.2]
  def change
    change_column_default :users, :last_logged_in_at, -> { 'CURRENT_TIMESTAMP' }
  end
end
