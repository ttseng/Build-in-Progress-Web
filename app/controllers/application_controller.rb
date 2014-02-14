class ApplicationController < ActionController::Base
	include PublicActivity::StoreController
  protect_from_forgery
  before_filter :set_notifications_viewed_at

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to errors_unauthorized_path
  end

  def after_sign_in_path_for(resource)
    sign_in_url = url_for(:action => 'new', :controller => 'sessions', :only_path => false, :protocol => 'http')
    if request.referer == sign_in_url
      super
    else
      stored_location_for(resource) || request.referer || root_path
    end
  end

   def set_notifications_viewed_at
    if current_user
      # update notification seen date if user clicks on notification link
      if !params[:notification_id].blank?
        PublicActivity::Activity.find(params[:notification_id]).update_attributes(:viewed=>true)
      end
    end
  end
  
end


