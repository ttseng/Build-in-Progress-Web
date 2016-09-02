class ProjectsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :embed, :builds, :built, :featured, :arts_and_crafts, :clothing, :cooking, :electronics, :mechanical, :other, :search, :imageView, :gallery, :blog, :timemachine] 

  # GET /projects
  # GET /projects.json
  def index
    if !params[:category].blank?
      @projects = Category.where(:name => params[:category]).first.projects.public_projects.order('updated_at DESC').page(params[:projects_page]).per_page(9).includes(:steps, :images)
    else
      @projects = Project.public_projects.order("updated_at DESC").page(params[:projects_page]).per_page(12).includes(:steps, :images)
    end
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.json { render :json => @projects }
    end
  end

  # GET /projects/featured - projects that have been featured
  def featured
    if !params[:category].blank?
      @projects = Category.where(:name => params[:category]).first.projects.public_projects.where(:featured=>true).order('updated_at DESC').page(params[:projects_page]).per_page(9)
    else
      @projects = Project.public_projects.where(:featured=>true).order("updated_at DESC").page(params[:projects_page]).per_page(9)
    end
    render :template => "projects/index"
  end

  # GET /projects/builds - projects that are still in progress
  def builds
    if !params[:category].blank?
      @projects = Category.where(:name => params[:category]).first.projects.public_projects.where(:built=>false).order('updated_at DESC').page(params[:projects_page]).per_page(9)
    else
      @projects = Project.public_projects.where(:built=> false).order("updated_at DESC").page(params[:projects_page]).per_page(9)
    end
    render :template =>"projects/index"
  end

  # GET /projects/built - projects that have been built
  def built
    if !params[:category].blank?
      @projects = Category.where(:name => params[:category]).first.projects.public_projects.where(:built=>true).order('updated_at DESC').page(params[:projects_page]).per_page(9)
    else
      @projects = Project.public_projects.where(:built=> true).order("updated_at DESC").page(params[:projects_page]).per_page(9)
    end
    render :template =>"projects/index"
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    begin
      @project = Project.find_by_id(params[:id])
      respond_to do |format|
        format.html {redirect_to project_steps_path(@project)}
      end
    rescue
      respond_to do |format|
        format.html {redirect_to url_for(:controller => "errors", :action => "show", :code => "404")}
      end
    end
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @project = Project.new

    respond_to do |format|
      format.html { create }
      format.json { create }
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
    authorize! :edit, @project
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(params[:project])

    # set some default values
    numUntitled = current_user.projects.where("title like ?", "%Untitled%").count
    @project.title = "Untitled-"+ (numUntitled+1).to_s()
    @project.built = false
    @project.users << current_user

    respond_to do |format|
      if @project.save
        # if user is from village, push project to village
        format.html { redirect_to @project }
        format.json { render :json => @project, :status => :created, :location => @project }
      else
        format.html { render :action => "new" }
        format.json { render :json => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.json
  def update
    @project = Project.find(params[:id])
    authorize! :update, @project
    @collections = @project.collections

    @collections.each do |collection|
      collection.touch
    end

    respond_to do |format|
      if @project.update_attributes(params[:project])
        
        if @project.privacy.blank?
            @project.set_published(current_user.id, @project.id, nil)
        elsif @project.title.downcase.include? "untitled"
            @project.set_published(current_user.id, @project.id, nil)
        end

        if @project.public? && @project.village_id.blank? && current_user.from_village? && !access_token.blank?
          Rails.logger.debug("creating village project")
          create_village_project(@project.id)
        elsif @project.published? && @project.village_id.present? && current_user.from_village? && access_token.present?
          Rails.logger.debug("updating village project")
          update_village_project(@project.id)          
        end
        format.html { redirect_to @project, :notice => 'Project was successfully updated.' }
        format.js
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project = Project.find(params[:id])
    authorize! :destroy, @project

    # delete activities having to do with the project
    PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "Project", @project.id).destroy_all
    @project.questions.each do |question|
      PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "Question", question.id).destroy_all
    end

    # delete all favorites
    favorite_entry = FavoriteProject.where(:user_id=>current_user.id).where(:project_id => @project.id).first
    if favorite_entry
      PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "FavoriteProject", favorite_entry.id).destroy_all
    end

    # delete all collectifies
    Collectify.where(:project_id=>@project.id).each do |collectify|
       collectify.destroy
    end

    @project.steps.each do |step|
      PublicActivity::Activity.where(:trackable_id => step.id).destroy_all
    end

    if !@project.village_id.blank?
      # delete project on the village
      destroy_village_project(@project.village_id)
    end

    # if project has descendants, set their remix_ancestry to nil or project's ancestor
    @project.descendants.each do |descendant|
      if @project.remix_ancestry == nil
        descendant.update_column("remix_ancestry", nil)
      else
        descendant.update_column("remix_ancestry", @project.remix_ancestry)
      end
    end

    # remove the log for project
    s3 = AWS::S3.new(:access_key_id => ENV['AWS_ACCESS_KEY_ID'], :secret_access_key => ENV['AWS_ACCESS_KEY'])
    key = "logs/" + @project.id.to_s + ".json"
    s3.buckets[ENV['AWS_BUCKET']].objects.with_prefix(key).delete_all

    @project.destroy

    respond_to do |format|
      format.html { redirect_to user_path(current_user.username) }
      format.json { head :no_content }
    end
  end

  # editTitle /project/1/editTitle
  def editTitle
    @projectID = params[:projectID]
    respond_to do |format|
      logger.debug("edit Title")
      format.js
    end
  end

  # PUT /projects/1/embed
  # Embed code for displaying Build-in-Progress project on another site
  def embed
    @project = Project.find(params[:id])
    @steps = @project.steps.order("position")
    @ancestry = @steps.pluck(:ancestry) # array of ancestry ids for all steps
    
    respond_to do |format|
      format.html {render :layout=> false}
      format.js
    end
  end

  # GET /project/1/imageView
  # imageView view of project
  def imageView
    @project = Project.find(params[:id])
    redirect_to gallery_project_url(@project)
  end

  # GET /projects/1/galery
  # gallery view of project
  def gallery
    @project = Project.find(params[:id])
  end

  # GET /projects/1/blog
  # blog view of project
  def blog
    @project = Project.find(params[:id])
  end

  # GET /projects/1/export
  # Expot a zip of a project page
  def export
    @project = Project.find(params[:id])
    @project.export
    if current_user && @project.users.include?(current_user)
      current_user.touch
    end
    send_file "#{Rails.root}/tmp/zips/#{@project.id}-#{@project.title.delete(' ')}.zip"
  end

  # GET /project/1/export_txt
  # Export a txt file of a project page
  def export_txt
    @project = Project.find(params[:id])
    @project.export_txt
    send_file "#{Rails.root}/tmp/txt/#{@project.id}.txt"
  end

  # Add and remove favorite projects for current user
  def favorite
    type=params[:type]
    @project = Project.find(params[:id])

    if type=="favorite"
      if current_user.favorites.include?(@project) == false
        current_user.favorites << @project
      end
      @project.users.each do |user|
        @activity = @project.favorite_projects.last.create_activity :create, owner: current_user, recipient: user, primary: true
        # create email notification
        if user.settings(:email).favorited == true
          NotificationEmailWorker.perform_async(@activity.id, user.id)
        end

      end
    elsif type=="unfavorite"
      favorite_entry = FavoriteProject.where(:user_id=>current_user.id).where(:project_id => @project.id).first
      PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "FavoriteProject", favorite_entry.id).destroy_all

      current_user.favorites.delete(@project)
    end
      redirect_to :back
  end

  # Create remix
  def remix
    @project = Project.find(params[:id])
    @remix_project = @project.remix(current_user)

    respond_to do |format|    
        format.html {
          redirect_to @remix_project 
        }   
    end
  end

  # find users to add to a project using the EditProjectAuthors Modal Form
  # params[:input] - string user has inputted into the search field
  # params[:project_id] - the id of the project being edited
  def find_users
    input = params[:input]
    project = Project.find(params[:project_id])

    # find all usernames that start with the input
    search_results = Array.new
    # first, filter by usernames that start with a particular letter
    User.pluck(:username).sort_by(&:downcase).select{|user| user[0,1]==input[0,1]}.each do |username|
      user = User.where(:username=>username).first
      if username.starts_with?(input) && project.users.include?(user) == false
        user_array = Array.new
        user_array.push(username)
        if user.avatar.present?
          user_array.push(user.avatar_url(:thumb))
        else
          user_array.push(ActionController::Base.helpers.asset_path("default_avatar.png"))
        end
        search_results.push(user_array)
      end
    end
    respond_to do |format|
      format.json {render :json => search_results}
    end
  end

  # add users to a project
  # params[:users] - an array of usernames that are being added to the project
  # params[:project_id] - the id of the project being edtied
  def add_users
    
      users = params[:users]
      project = Project.find(params[:project_id])
      authorize! :add_users, project

      users.each do |user|
        new_user = User.where(:username=>user).first
        if !project.users.pluck(:username).include? user
          project.users << new_user
          # create activity
          @activity = project.create_activity :author_add, owner: current_user, recipient: new_user, primary: true
          # create mailer
          if new_user.settings(:email).collaborator == true
            NotificationEmailWorker.perform_async(@activity.id, new_user.id)
          end
        end
      end

      if project.village_id.blank? && current_user.from_village? && project.public? && !access_token.blank?
        create_village_project(project.id)
      elsif !project.village_id.blank? && !access_token.blank?
        update_village_project(project.id)
      end

    respond_to do |format|
      format.json {render :json => true}
    end
  end

  # remove user from a project
  # params[:user] - the usernames that is being removed from the project
  # params[:project_id] - the id of the project being edtied
  def remove_user
      username = params[:username]
      @project = Project.find(params[:project_id])
      Rails.logger.debug("in remove_user")
      authorize! :remove_user, @project

      @project_user = User.where(:username=>username).first
      @project.users.delete(@project_user)
      # remove activity
      PublicActivity::Activity.where("key = ? and trackable_id = ? and recipient_id = ?", "project.author_add", @project, @project_user.id).destroy_all

      if @project_user.from_village? && @project.village_id.present?
        update_village_project(@project.id)
      end

    respond_to do |format|
      format.json {render :json => true}
    end
  end

  # create village project
  def create_village_project(project_id)
    @project = Project.find(project_id)
    iframe_src = "<iframe src='" + root_url.sub(/\/$/, '') + embed_project_path(@project) + "' width='555' height='490'></iframe><p>This project created with <b><a href='" + root_url + "'>#{ENV[APP_NAME]}</a></b> and updated on " + Time.now.strftime("%A, %B %-d at %-I:%M %p") +"</p>"
    iframe_src = iframe_src.html_safe.to_str
    village_user_ids = @project.village_user_ids
    response = access_token.post("/api/projects", params: {project: {name: @project.title, project_type_id: 15, source: "original", description: iframe_src, thumbnail_file_id: 764899, user_ids: village_user_ids} })
    village_project_id = response.parsed["project"]["id"]
    @project.update_attributes(:village_id => village_project_id)
  end

 # update a project on the village
  def update_village_project(project_id)
    logger.debug("in update village project")
    @project = Project.find(project_id)
    iframe_src = "<iframe src='" + root_url.sub(/\/$/, '') + embed_project_path(@project) + "' width='575' height='485'></iframe><p>This project created with <b><a href='" + root_url + "'>#{ENV["APP_NAME"]}</a></b> and updated on " + Time.now.strftime("%A, %B %-d at %-I:%M %p") +"</p>"
    iframe_src = iframe_src.html_safe.to_str
    village_user_ids = @project.village_user_ids
    logger.debug("village_user_ids: #{village_user_ids}")
    logger.debug("access_token: #{access_token}")
    response = access_token.put("/api/projects/" + @project.village_id.to_s, params: {project: {name: @project.title, description: iframe_src, user_ids: village_user_ids }})
  end

  # delete project from village if it's deleted
  def destroy_village_project(village_id)
    # Rails.logger.debug('trying to delete village project')
    # Rails.logger.debug('village delete url: ' + "api/projects/"+village_id.to_s)
    if(access_token)
      response = access_token.delete("api/projects/"+village_id.to_s)
    end
    # Rails.logger.debug('deleted project on village')
  end

  # apply category to project
  def categorize
      @project = Project.find(params[:id])
      authorize! :categorize, @project

      logger.debug "#{params}"

      arts_and_crafts = params[:arts_and_crafts]
      clothing = params[:clothing]
      cooking = params[:cooking]
      electronics = params[:electronics]
      mechanical = params[:mechanical]
      other = params[:other]

      arts_and_crafts_category = Category.where(:name => "Arts & Crafts").first
      clothing_category = Category.where(:name => "Clothing").first
      cooking_category = Category.where(:name => "Cooking").first
      electronics_category = Category.where(:name => "Electronics").first
      mechanical_category = Category.where(:name => "Mechanical").first
      other_category = Category.where(:name => "Other").first

      if arts_and_crafts == "1" and !@project.categories.include?(arts_and_crafts_category)
        arts_and_crafts_category.categorizations.create!(:project_id => @project.id)
      elsif arts_and_crafts != "1" and @project.categories.include?(arts_and_crafts_category)
        Categorization.where("category_id = ? AND project_id = ?", arts_and_crafts_category.id, @project.id).first.destroy
      end

      if clothing == "1" and !@project.categories.include?(clothing_category)
        clothing_category.categorizations.create!(:project_id => @project.id)
      elsif clothing != "1" and @project.categories.include?(clothing_category)
        Categorization.where("category_id = ? AND project_id = ?", clothing_category.id, @project.id).first.destroy
      end

      if cooking == "1" and !@project.categories.include?(cooking_category)
        cooking_category.categorizations.create!(:project_id => @project.id)
      elsif cooking != "1" and @project.categories.include?(cooking_category)
        Categorization.where("category_id = ? AND project_id = ?", cooking_category.id, @project.id).first.destroy
      end

      if electronics == "1" and !@project.categories.include?(electronics_category)
        electronics_category.categorizations.create!(:project_id => @project.id)
      elsif electronics != "1" and @project.categories.include?(electronics_category)
        Categorization.where("category_id = ? AND project_id = ?", electronics_category.id, @project.id).first.destroy
      end

      if mechanical == "1" and !@project.categories.include?(mechanical_category)
        mechanical_category.categorizations.create!(:project_id => @project.id)
      elsif mechanical != "1" and @project.categories.include?(mechanical_category)
        Categorization.where("category_id = ? AND project_id = ?", mechanical_category.id, @project.id).first.destroy
      end

      if other == "1" and !@project.categories.include?(other_category)
        other_category.categorizations.create!(:project_id => @project.id)
      elsif other != "1" and @project.categories.include?(other_category)
        Categorization.where("category_id = ? AND project_id = ?", other_category.id, @project.id).first.destroy
      end

    respond_to do |format|
      format.html { redirect_to @project, :notice => 'Project was successfully updated.' }
      format.js
      format.json { render :json => true }
    end
  end

  def search
    @search_term = params[:search]
    @projects = params[:search_results]
    if !@projects.nil?
      @projects = @projects.collect{|s| s.to_i}
    end

    search_category = params[:category]

    @projects_text = params[:search_text]

    @project_count = params[:project_count] ||= "0"
    @collection_count = params[:collection_count] ||= "0"
    @user_count = params[:user_count] ||= "0"

    if !search_category.blank? && search_category != "All Categories"
      category = Category.where(:name=>search_category).first
      c_filtered_projects = []
      search_count = 0
      @projects.each do |project|
        project = Project.find(project.to_i)
        if project.categories.include?(category)
          c_filtered_projects = c_filtered_projects << project
          search_count = search_count + 1
        end
      end
      @projects = c_filtered_projects
      @project_count = search_count.to_s
    end

    if !params[:type].blank? && params[:type] != "All Projects"
      search_count = 0
      t_filtered_projects = []
      if params[:type] == "Featured Projects"
        @projects.each do |project|
          if project.class == Fixnum
            project = Project.find(project)
          end
          if project.featured == true
            t_filtered_projects = t_filtered_projects << project
            search_count = search_count + 1
          end
        end
      elsif params[:type] == "Builds in Progress"
        @projects.each do |project|
          if project.class == Fixnum
            project = Project.find(project)
          end
          if project.built == false
            t_filtered_projects = t_filtered_projects << project
            search_count = search_count + 1
          end
        end
      elsif params[:type] == "Built Projects"
        @projects.each do |project|
          if project.class == Fixnum
            project = Project.find(project)
          end
          if project.built == true
            t_filtered_projects = t_filtered_projects << project
            search_count = search_count + 1
          end
        end
      end
      @projects = t_filtered_projects
      @project_count = search_count.to_s
    end

    respond_to do |format|
      format.html
      format.js
      format.json { render :json => @projects }
    end
  end

  # add new log entry for reordering steps in process map
  def log
    Project.find(params[:id]).log
    respond_to do |format|
        format.js {render nothing: true}
    end
  end

  def update_privacy
    @project = Project.find(params[:id]) 
    Project.record_timestamps = false
    @project.update_attributes(:privacy => params[:privacy])
    Project.record_timestamps = true
    if params[:privacy] == "private"
      # remove project from any collections
      collectifies = Collectify.where(:project_id => @project.id)
      collectifies.each do |collectify|
        authorize! :destroy, Collectify.find(collectify.id)
        PublicActivity::Activity.where(:trackable_id => collectify.id).destroy_all
        collectify.collection.remove!(@project)
        if !collectify.collection.published?
          collectify.collection.update_attributes(:published=>false)
          PublicActivity::Activity.where(:trackable_id => @collection).destroy_all
        end
      end
    end
    respond_to do |format|
      format.html{
        redirect_to @project
      }
    end
  end

  # check_privacy | returns whether or not a project is public, private, or unlisted
  def check_privacy
    project_privacy = ""
    project_title = ""

    uri = URI(params[:project_url])
    project_id = uri.path.match('\/projects\/\d+\/').to_s.match('\d+').to_s
    if project_id == ""
      project_id = uri.path.split('/').last.to_s
    end
    
    if project_id != ""
      @project = Project.find(project_id)
      project_name = @project.title
      project_privacy = @project.privacy
      if !project_privacy
        project_privacy = "unpublished"
      end
    end

    response_json = {"project_name" => project_name, "project_privacy" => project_privacy}
    respond_to do |format|
      format.json {render :json => response_json}
    end

  end

    # log viewer for project
  def timemachine
    @project = Project.find(params[:id])
    authorize! :timemachine, @project  

    @steps = @project.steps.order("position")
    @numSteps = @steps.count
    @ancestry = @steps.pluck(:ancestry) # array of ancestry ids for all steps
    @allBranches # variable for storing the tree structure of the process map
    # fetch the log from aws
    s3 = AWS::S3.new(:access_key_id => ENV['AWS_ACCESS_KEY_ID'], :secret_access_key => ENV['AWS_ACCESS_KEY'])
    key = "logs/" + @project.id.to_s + ".json"
    
    obj = s3.buckets[ENV['AWS_BUCKET']].objects[key]

    if obj.exists?
      @project_json = JSON.parse(obj.read)
      
      # create thumbnails array containing image information for each log
      @thumbnails = []
      @project_json["data"].each do |log_entry|
        step_ids = log_entry["steps"].map(&:first).map(&:last)
        img_array = @project.thumbnail_images(step_ids)
        @thumbnails << img_array
      end
      puts @thumbnails

    else
      redirect_to @project
    end
  end

end