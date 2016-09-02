class RegistrationsController < Devise::RegistrationsController

	skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  	respond_to :json

  	def create
	    user = User.new(params[:user])
	    
	    # comment out following line to re-enable confirmation
	    # resource.skip_confirmation!

	    if user.save
	      sign_in user, :email => user.unconfirmed_email
	      render :status => 200,
	           :json => { :success => true,
	                      :info => "Registered",
	                      :data => { :user => user,
	                                 :auth_token => current_user.authentication_token } }
	    else
	    	redirect_to new_user_registration_path, notice: user.errors.full_messages[0]
		    # render :status => :unprocessable_entity,
		    #          :json => { :success => false,
		    #                     :info => resource.errors,
		    #                     :data => {} }
	    end
	end

	def update
		@user = User.find(current_user.id)
		authorize! :update, @user
		account_update_params = params[:user]
		update_email = false # used to determine if user is just editing their email address
		update_profile = false # used to determine if user is just editing their profile page

		if params[:rails_settings_setting_object]
			params[:rails_settings_setting_object].each do |key, value|
				current_user.settings(:email).update_attributes! key.to_sym => value=="1"
			end
			if params[:user][:email] == @user.email
				# update just the user's mail settings
				redirect_to :back, notice: "Updated email preferences!", :anchor=>"email-tab"
			else
				# require confirmation
				account_update_params.delete("password")
				account_update_params.delete("password_confirmation")
				
				self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    			prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    			if @user.update_attributes(account_update_params)
			      yield resource if block_given?
			      if is_navigational_format?
			        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
			          :update_needs_confirmation : :updated
			        set_flash_message :notice, flash_key
			      end
			      sign_in resource_name, resource, bypass: true
			      respond_with resource, location: after_update_path_for(resource)
			    else
			      clean_up_passwords resource
			      respond_with resource
			    end
			  end
		else
			if account_update_params[:password].blank?
				if !params[:user][:email].blank?
					logger.debug('setting update email to true')
					update_email = true
				else
					logger.debug('setting update profile to true')
					update_profile = true
				end				
				account_update_params.delete("password")
				account_update_params.delete("password_confirmation")

				if @user.update_attributes(account_update_params) 
					if update_email
						set_flash_message :alert, :signed_up_but_unconfirmed
						@user.send_confirmation_instructions
					else
						set_flash_message :notice, :updated
					end
				redirect_to after_update_path_for(@user)
				end

			elsif @user.update_with_password(account_update_params)
				set_flash_message :notice, :updated
				sign_in @user, :bypass => true
				redirect_to after_update_path_for(@user)
			else
				redirect_to :back, alert: resource.errors.full_messages[0]
			end
		end

	end


	protected
	
	def after_update_path_for(resource)
		user_path(resource)
	end

end
