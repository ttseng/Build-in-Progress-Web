class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  
  def village
    # raise request.env["omniauth.auth"].to_yaml
    auth = request.env["omniauth.auth"]
    Rails.logger.info("omniauth.auth: " + auth.inspect)
    user = User.from_village_omniauth(auth)
    Rails.logger.info('user: ' + user.attributes.inspect )

    if user.persisted?
    	Rails.logger.info("signing in!")
      session[:user_id] = user.id
      session[:access_token] = auth["credentials"]["token"]
      user.update_attribute(:access_token, session[:access_token])
      logger.debug("uid: #{session[:user_id]}, with token: #{session[:access_token]}")
    	flash[:notice] = "Signed in with your Village account!"
    	sign_in_and_redirect user
    else
    	Rails.logger.info("redirecting to registration")
    	session["devise.user_attributes"] = user.attributes
    	redirect_to new_registration_path(resource_name)
    end
  end

  def google_oauth2
    auth = request.env["omniauth.auth"]
    Rails.logger.info("omniauth.auth: " + auth.inspect)
    user = User.from_google_omniauth(auth)
    Rails.logger.info('user: ' + user.attributes.inspect)
    
    if user.persisted?
      # create new user with this google account
      Rails.logger.info("signing in!")
      session[:user_id] = user.id
      flash[:notice] = "Signed in with your Google account!"
      sign_in_and_redirect user
    else
      if User.where(:username => user.email.split("@").first).exists?
        # a user with this username already exists 
        # if you previously created this account, please log in and connect your account to Google in your Account Settings
        # if you did not create this account, please enter in a new username for your account

        # for now, link this account to google (very small # of users who had BiP accounts before Google Authentication integration 
        # will be trying to log in using it now...just connect their accounts, though this is a security loophole...)
        Rails.logger.info("username already exists")
        existing_user = User.where(:username => user.email.split("@").first).first
        existing_user.update_attributes(:provider => "google_oauth2", :uid => auth.uid)
        session[:user_id] = existing_user.id
        flash[:notice] = "Signed in with your Google account!"
        sign_in_and_redirect existing_user

      elsif User.where(:email => user.email).exists?
        # log in an existing user with their google credentials
        Rails.logger.info("email already exists")
        existing_user = User.where(:email => user.email).first
        existing_user.update_attributes(:provider => "google_oauth2", :uid => auth.uid)
        session[:user_id] = existing_user.id
        flash[:notice] = "Signed in with your Google account!"
        sign_in_and_redirect existing_user
      else
        Rails.logger.info("redirecting to registration")
        session["devise.user_attributes"] = user.attributes
        redirect_to new_registration_path(resource_name)   
      end   
    end
  end

end