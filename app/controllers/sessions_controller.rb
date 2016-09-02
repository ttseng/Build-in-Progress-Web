class SessionsController < Devise::SessionsController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  respond_to :json

  def new
    if params[:email]
      email = params[:email]
      logger.debug("email :#{email}")
      flash[:email] = email
    end
  end

  def create
    user = User.find_for_authentication(:username=>params[:user][:username])
    if user && user.valid_password?(params[:user][:password])
      user.last_sign_in_at = Time.now
      user.sign_in_count = user.sign_in_count + 1
      # generate token if it doesn't exist
      if user.authentication_token.blank?
          # Rails.logger.debug "generating authentication token for #{user.username} #{user.id}"
          new_token = generate_authentication_token
          # Rails.logger.debug "new authentication token: #{new_token}"
          user.update_column("authentication_token", new_token)
      end

       render :status => 200,
           :json => { :success => true,
                      :info => "Logged in",
                      :data => { :auth_token => user.authentication_token } }
        # Rails.logger.debug "current user: #{current_user.username} #{current_user.id}"
        # Rails.logger.debug "current user authentication_token: #{current_user.authentication_token}"
    else
        render :status => 401,
         :json => { :success => false,
                    :info => "Login Failed",
                    :data => {} }
    end

    # respond_to do |format|
    #   format.html { super }
    #   format.xml {
    #     warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")
    #     render :status => 200, :xml => { :session => { :error => "Success", :auth_token => current_user.authentication_token }}
    #   }
 
    #   format.json {
    #     warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")
    #     render :status => 200, :json => { :session => { :error => "Success", :auth_token => current_user.authentication_token } }
    #   }
    # end
  end
 
  def destroy
    warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
    # current_user.update_column(:authentication_token, nil)
    render :status => 200,
           :json => { :success => true,
                      :info => "Logged out",
                      :data => {} }
    session[:user_id] = nil
    session[:access_token] = nil
    # respond_to do |format|
    #   format.html { super }
    #   format.xml {
    #     warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")
    #     current_user.authentication_token = nil
    #     render :xml => {}.to_xml, :status => :ok
    #   }
 
    #   format.json {
    #     warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")
    #     current_user.authentication_token = nil
    #     render :json => {}.to_json, :status => :ok
    #   }   
    # end    
  end

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end

  def failure
    render :status => 401,
           :json => { :success => false,
                      :info => "Login Failed",
                      :data => {} }
  end

  def omniauth_failure
    if params[:error] && params[:error] == "access_denied"
      flash[:error] = "Access denied, try again"
    else
      flash[:error] = "Access problem: #{params[:error_description]}"
    end
    redirect_to root_url
  end
  
end
