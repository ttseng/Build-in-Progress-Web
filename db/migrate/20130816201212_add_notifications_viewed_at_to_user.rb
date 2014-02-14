class AddNotificationsViewedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :notifications_viewed_at, :datetime
  end
end
