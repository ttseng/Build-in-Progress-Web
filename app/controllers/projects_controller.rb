class ProjectsController < ApplicationController

  before_filter :authenticate_user!, except: [:index, :show, :builds, :built, :featured, :arts_and_crafts, :clothing, :cooking, :electronics, :mechanical, :other] 
  # GET /projects
  # GET /projects.json
  def index
    if !params[:category].blank?
      @projects = Category.where(:name => params[:category]).first.projects.published.order('updated_at DESC').page(params[:projects_page]).per_page(9)
    else
      @projects = Project.published.order("updated_at DESC").page(params[:projects_page]).per_page(9)
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
      @projects = Category.where(:name => params[:category]).first.projects.published.where(:featured=>true).order('updated_at DESC').page(params[:projects_page]).per_page(9)
    else
      @projects = Project.published.where(:featured=>true).order("updated_at DESC").page(params[:projects_page]).per_page(9)
    end
    render :template => "projects/index"
  end

  # GET /projects/builds - projects that are still in progress
  def builds
    if !params[:category].blank?
      @projects = Category.where(:name => params[:category]).first.projects.published.where(:built=>false).order('updated_at DESC').page(params[:projects_page]).per_page(9)
    else
      @projects = Project.published.where(:built=> false).order("updated_at DESC").page(params[:projects_page]).per_page(9)
    end
    render :template =>"projects/index"
  end

  # GET /projects/built - projects that have been built
  def built
    if !params[:category].blank?
      @projects = Category.where(:name => params[:category]).first.projects.published.where(:built=>true).order('updated_at DESC').page(params[:projects_page]).per_page(9)
    else
      @projects = Project.published.where(:built=> true).order("updated_at DESC").page(params[:projects_page]).per_page(9)
    end
    render :template =>"projects/index"
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @project = Project.find(params[:id])
    @step = 0

    respond_to do |format|
      format.html {
        redirect_to project_steps_path(@project)
      }
      format.json { }
    end
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @project = Project.new

    respond_to do |format|
      format.html { create }
      format.json { render :json => @project }
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
    @project.published = false
    @project.users << current_user

    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, :notice => 'Project was successfully created.' }
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
    @collections = @project.collections

    @collections.each do |collection|
      collection.touch
    end

    respond_to do |format|
      if @project.update_attributes(params[:project])
        if @project.published? and !@project.published
          if @project.is_remix?
            # create a notification for the parent and original author
            @project.ancestors.each do |ancestor|
              @project.create_activity :create, owner: current_user, recipient: ancestor.user, primary: true
            end
          else
            @project.create_activity :new, owner: current_user, primary: true
          end
          @project.update_attributes(:published=>true)

        elsif @project.published?
          @project.update_attributes(:published=>true)

        else
          PublicActivity::Activity.where(:trackable_id => @project.id).destroy_all
    
          @project.steps.each do |step|
            PublicActivity::Activity.where(:trackable_id => step.id).destroy_all
          end
          
          @project.update_attributes(:published=>false)
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

    favorite_entry = FavoriteProject.where(:user_id=>current_user.id).where(:project_id => @project.id).first
    if favorite_entry
      PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "FavoriteProject", favorite_entry.id).destroy_all
    end

    collectifies = Collectify.where(:project_id=>@project)
    collectifies.each do |collectify|
       collectify.destroy
    end

    @project.steps.each do |step|
      PublicActivity::Activity.where(:trackable_id => step.id).destroy_all
    end

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
    respond_to do |format|
      format.html {render :layout=> false}
      format.js
    end
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
        @project.favorite_projects.last.create_activity :create, owner: current_user, recipient: user, primary: true
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

    users.each do |user|
      new_user = User.where(:username=>user).first
      if !project.users.pluck(:username).include? new_user
        project.users << new_user
        # create activity
        project.create_activity :author_add, owner: current_user, recipient: new_user, primary: true
      end
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
    project = Project.find(params[:project_id])

    project_user = User.where(:username=>username).first
    project.users.delete(project_user)
    # remove activity
    PublicActivity::Activity.where("key = ? and trackable_id = ? and recipient_id = ?", "project.author_add", project, project_user.id).destroy_all

    respond_to do |format|
      format.json {render :json => true}
    end
  end

  # apply category to project
  def categorize
    @project = Project.find(params[:id])
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
end