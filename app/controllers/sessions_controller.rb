class SessionsController < Devise::SessionsController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  respond_to :json


  def create
    warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
    render :status => 200,
           :json => { :success => true,
                      :info => "Logged in",
                      :data => { :auth_token => current_user.authentication_token } }

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
    current_user.update_column(:authentication_token, nil)
    render :status => 200,
           :json => { :success => true,
                      :info => "Logged out",
                      :data => {} }
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

  def failure
    render :status => 401,
           :json => { :success => false,
                      :info => "Login Failed",
                      :data => {} }
  end
  
end
