class RegistrationsController < Devise::RegistrationsController

	skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  	respond_to :json

  	def create
	    user = User.new(params[:user])
	    Rails.logger.info(user.inspect)
	    # comment out following line to re-enable confirmation
	    # resource.skip_confirmation!

	    if user.save
	      sign_in user
	      render :status => 200,
	           :json => { :success => true,
	                      :info => "Registered",
	                      :data => { :user => user,
	                                 :auth_token => current_user.authentication_token } }
	    else
	    	redirect_to new_user_registration_path, notice: user.errors.full_messages[0]
	    	Rails.logger.info(user.errors.inspect)
	      # render :status => :unprocessable_entity,
	      #        :json => { :success => false,
	      #                   :info => resource.errors,
	      #                   :data => {} }
	    end
	end

	def update
		@user = User.find(current_user.id)
		successfully_updated = if needs_password?(@user, params)
			@user.update_with_password(params[:user])
		else
			# remove the virtual current_password attribute 
			params[:user].delete(:current_password)
			@user.update_without_password(params[:user])
		end
		
		if successfully_updated
			if params[:update_email]
				set_flash_message :alert, :signed_up_but_unconfirmed
				redirect_to after_update_path_for(@user)
			else			
				set_flash_message :notice, :updated
				sign_in @user, :bypass => true
				redirect_to after_update_path_for(@user)
			end
		else
			redirect_to :back, alert: resource.errors.full_messages[0]
		end
	end

		private

	# check if we need password to update user data
	def needs_password?(user,params)
		!params[:profile]
	end
	
	protected
	
	def after_update_path_for(resource)
		user_path(resource)
	end

end
