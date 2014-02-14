class NotificationsController < ApplicationController
	before_filter :authenticate_user!

  def index
    current_user.all_notifications.each do |new_notification|
    	new_notification.update_attributes(:viewed=>true)
    end
  end

end
