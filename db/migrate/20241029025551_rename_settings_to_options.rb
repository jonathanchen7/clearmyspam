class RenameSettingsToOptions < ActiveRecord::Migration[7.2]
  def change
    rename_table :settings, :options
  end
end
