class MakeUserLastLoggedInAtNonNull < ActiveRecord::Migration[7.2]
  def change
    change_column_null :users, :last_logged_in_at, false
  end
end
