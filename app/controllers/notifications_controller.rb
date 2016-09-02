class NotificationsController < ApplicationController
	before_filter :authenticate_user!

  def index
  	# used to highlight new notifications on notification page
    @new_notification_ids = current_user.all_new_notifications.collect(&:id)
    
    current_user.all_notifications.each do |new_notification|
    	new_notification.update_attributes(:viewed=>true)
    end

    # get current user's notifications
    @notifications = current_user.all_notifications.paginate(:page => params[:notifications_page], :per_page => 10)
  end

end
