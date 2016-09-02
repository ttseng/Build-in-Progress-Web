class RemoveEmailNotifyFromUser < ActiveRecord::Migration
  def up
  	remove_column :users, :email_notify
  end
  
end
