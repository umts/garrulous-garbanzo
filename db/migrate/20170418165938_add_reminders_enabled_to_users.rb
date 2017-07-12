class AddRemindersEnabledToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :reminders_enabled, :boolean, default: true
  end
end
