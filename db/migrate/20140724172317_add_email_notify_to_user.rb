class AddEmailNotifyToUser < ActiveRecord::Migration
  def change
    add_column :users, :email_notify, :boolean
  end
end
