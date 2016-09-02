class UsersController < ApplicationController
	#users_controller.rb
	before_filter :get_category_count, except: [:search]

	# retrieve the categories for the user_info partial
	def get_category_count
		if(params[:id])
			@user = User.find(params[:id].downcase)
		
			@all_projects = @user.projects.order("updated_at DESC")

			@arts_and_crafts_count = 0
			@clothing_count = 0
			@cooking_count = 0
			@electronics_count = 0
			@mechanical_count = 0
			@other_count = 0

			arts_and_crafts_category = Category.where(:name => "Arts & Crafts").first
		    clothing_category = Category.where(:name => "Clothing").first
		    cooking_category = Category.where(:name => "Cooking").first
		    electronics_category = Category.where(:name => "Electronics").first
		    mechanical_category = Category.where(:name => "Mechanical").first
		    other_category = Category.where(:name => "Other").first

		    @all_projects.each do |project|
			    if project.categories.include?(arts_and_crafts_category)
			      @arts_and_crafts_count += 1
			    end

			    if project.categories.include?(clothing_category)
			      @clothing_count += 1
			    end

			    if project.categories.include?(cooking_category)
			      @cooking_count += 1
			    end

			    if project.categories.include?(electronics_category)
			      @electronics_count += 1
			    end

			    if project.categories.include?(mechanical_category)
			      @mechanical_count += 1
			    end

			    if project.categories.include?(other_category)
			      @other_count += 1
			    end
	    	end
	    end
	end

	def show
		if current_user == @user
			@projects = @user.projects.order("updated_at DESC").page(params[:projects_page]).per_page(9)
		else
			# only show public projects
			@projects = @user.projects.public_projects.order("updated_at DESC").page(params[:projects_page]).per_page(9)
		end
		@authorLoggedIn = current_user == @user
		@favoriteProjects = @user.favorite_projects.order("updated_at DESC").page(params[:favorites_page]).per_page(9)
		@collections = @user.collections.order("updated_at DESC").page(params[:collections_page]).per_page(9)

		respond_to do |format|
			format.html 
			format.json {
				# don't allow users to load this page unless they're admin
				if params[:auth_token].present?
					Rails.logger.debug("current_user #{current_user.username}")
					if !current_user.admin? && @user.authentication_token != params[:auth_token]
						redirect_to errors_unauthorized_path
					end
				elsif ( (current_user && current_user != @user) && (!current_user.admin?) ) || current_user.blank?
					redirect_to errors_unauthorized_path
				end
			}
			format.xml { render :xml => @projects}
		end
	end 

	def edit_profile
		authorize! :edit_profile, @user
		respond_to do |format|
			format.html
		end
	end
	
	# validate uniqueness of email
	def validate_email
		email = params[:email]
		# valid if username doesn't exist already
		valid = !User.pluck(:email).include?(email)
		respond_to do |format|
			format.json {render :json => valid}
		end
	end

	def validate_username
		username = params[:username]
		# valid if username doesn't exist already
		valid = !User.pluck(:username).include?(username)
		respond_to do |format|
			format.json {render :json => valid}
		end
	end

	# GET /user/username/projects
	def projects
		@projects = @user.projects.order("updated_at DESC")
		respond_to do |format|
			format.html
		end
	end

	# GET /user/username/projects
	def favorites
		@favoriteProjects = @user.favorite_projects.order("updated_at DESC")
		respond_to do |format|
			format.html
		end
	end

	# GET /user/username/collections
	def collections
		@collections = @user.collections.order("updated_at DESC")
		respond_to do |format|
			format.html
		end
	end

	def follow
	  if current_user
	    current_user.follow(@user)
	  	@activity = @user.create_activity :follow, owner: current_user, recipient: @user, primary: true
	  	# create email notification
	  	if @user.settings(:email).followed == true
	  		NotificationEmailWorker.perform_async(@activity.id, @user.id)
	  	end
	  end

	  respond_to do |format|
		format.js
		format.html { redirect_to user_path(@user)}
	  end
	end

	def unfollow
	  if current_user
	    current_user.stop_following(@user)
	    PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "User", @user.id).destroy_all
	  end
	  
	  respond_to do |format|
		format.js
		format.html { redirect_to user_path(@user) }
	  end
	end

	def following
	    @following = @user.following_users.page(params[:following_page])

	    respond_to do |format|
	      format.html # index.html.erb
	      format.js
	      format.json { render :json => @following }
	    end
  	end

  	def followers
	    @followers = @user.user_followers.page(params[:followers_page])

	    respond_to do |format|
	      format.html # index.html.erb
	      format.js
	      format.json { render :json => @followers }
	    end
  	end

  	def search
	    @search_term = params[:search]
	    @users = params[:search_results]
	    @users_text = params[:search_text]

	    @project_count = params[:project_count] ||= "0"
	    @collection_count = params[:collection_count] ||= "0"
	    @user_count = params[:user_count] ||= "0"

	    respond_to do |format|
	      format.html
	      format.js
	      format.json { render :json => @users }
    	end
  	end

  	# touch: update the user's updated at date if logged in
  	def touch
  		if current_user
  			current_user.touch 		
  		end
  		respond_to do |format|
  			format.json {render :nothing => true}
  		end
  	end
end