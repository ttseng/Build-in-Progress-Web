class UsersController < ApplicationController
	#users_controller.rb
	before_filter :get_category_count

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
		@projects = @user.projects.order("updated_at DESC").page(params[:projects_page]).per_page(9)
		@favoriteProjects = @user.favorite_projects.order("updated_at DESC").page(params[:favorites_page]).per_page(9)
		@collections = @user.collections.order("updated_at DESC").page(params[:collections_page]).per_page(9)

		respond_to do |format|
			format.html 
			format.json 
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
	  	@user.create_activity :follow, owner: current_user, recipient: @user, primary: true
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
end