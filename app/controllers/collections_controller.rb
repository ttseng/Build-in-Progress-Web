class CollectionsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :challenges, :search]

  def index
    @collections = Collection.published.order("updated_at DESC").where(:privacy => "public").page(params[:collections_page]).per_page(9)

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.json { render :json => @collections }
    end
  end

  # GET /collections/challenges 
  def challenges
    @collections = Collection.published.where(:challenge=>true).order("updated_at DESC").page(params[:collections_page]).per_page(9)
    render :template=>"collections/index"
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    @collection = Collection.find(params[:id])
    @authorLoggedIn = current_user == @collection.user

    if (@collection.private? && !current_user) || (@collection.private? && @collection.collection_users.include?(current_user) == false)
      respond_to do |format|
        format.html {redirect_to errors_unauthorized_path}
      end
    else
      step_ids = Step.joins(:project => :collectifies).where(collectifies: { collection_id: @collection.id }).pluck(:'steps.id')

      @questions = Question.where(:step_id => step_ids).where(:featured => nil).order("created_at DESC")
      @activities = PublicActivity::Activity.where(:trackable_type => "Step").where("trackable_id" => step_ids).where("key" => "step.create").order("created_at DESC").first(5)
      @contributors = @collection.projects.flat_map {|p| p.users}.uniq

      respond_to do |format|
        format.html {
            if request.path != collection_path(@collection)
                redirect_to @collection, status: :moved_permanently
            end
        }
        format.json { render :json => @collections }
      end

    end
  end

  # GET /collections/new
  # GET /collections/new.json
  def new
    @collection = Collection.new
    respond_to do |format|
      format.html { create }
      format.json { render :json => @collection }
    end
  end

  # GET /collections/1/edit
  def edit
    @collection = Collection.find(params[:id])
    authorize! :edit, @collection
  end

  # POST /collections
  # POST /collections.json
  def create
    @collection = current_user.collections.build(params[:collection])

    # set some default values - set collection value to the number of current collections
    if Collection.where("name like ?", "%Untitled%").count > 0
      count = Collection.where("name like ?", "%Untitled%").order("created_at DESC").first.name.sub('Untitled-Collection-','').to_i + 1
    else
      count = 1
    end
    
    @collection.name = "Untitled-Collection-"+count.to_s()
    @collection.user = current_user
    @collection.challenge = false
    @collection.privacy = "unlisted"

    respond_to do |format|
      if @collection.save
        @collection.update_attributes(:name => "Untitled-Collection-" + @collection.id.to_s)
        format.html { redirect_to @collection }
        format.json { render :json => @collection, :status => :created, :location => @collection }
      else
        format.html { render :action => "new" }
        format.json { render :json => @collection.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /collections/1
  # PUT /collections/1.json
  def update
    @collection = Collection.find(params[:id])
    authorize! :update, @collection

    respond_to do |format|
      if @collection.update_attributes(params[:collection])
        # create a new activity if the project is now published
        if @collection.published?
          # if collection is being published for the first time, add a public activity for it
          if @collection.published == false
            if @collection.unlisted?
              @collection.update_attributes(:privacy => "public")
            end
            @collection.create_activity :create, owner: current_user, primary: true
            # create notifications for the projects that are part of the collection
            collectifies = Collectify.where(:collection_id => @collection)
            collectifies.each do |collectify|
              if PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "Collectify", collectify.id).blank? 
                  # add public activity
                  collectify.project.users.each do |user|
                    collectify.create_activity :create, owner: current_user, recipient: user, primary: true
                    if current_user != @collection.user and user != @collection.user
                      collectify.create_activity :owner_create, owner: current_user, recipient: @collection.user, primary: true
                    end
                  end
              end
            end
          end
        @collection.update_attributes(:published=>true)
      else
        collectifies = Collectify.where(:collection_id=>@collection)
        collectifies.each do |collectify|
           PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "Collectify", collectify.id).destroy_all 
        end
        PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "Collection", @collection.id).destroy_all
      end

        format.html { redirect_to @collection }
        format.js
        format.json { head :no_content }
      else
        Rails.logger.debug "#{@collection.errors.inspect}"
        format.js { render :action=> "edit"}
        format.html { render :action => "edit" }
        format.json { render :json => @collection.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /collections/1
  # DELETE /collections/1.json
  def destroy
    @collection = Collection.find(params[:id])
    authorize! :destroy, @collection

    collectifies = Collectify.where(:collection_id=>@collection)
    collectifies.each do |collectify|
      PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "Collectify", collectify.id).destroy_all 
    end

    PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "Collection", @collection.id).destroy_all

    @collection.destroy

    respond_to do |format|
      format.html { redirect_to user_path(current_user.username) }
      format.json { head :no_content }
    end
  end

  def add_project
    @collection = Collection.find(params[:id])
    uri = URI(params[:project_url])
    project_id = uri.path.match('\/projects\/\d+\/').to_s.match('\d+').to_s

    if project_id == ""
      project_id = uri.path.split('/').last.to_s # account for users who don't include "steps" at the end
    end

    if project_id != ""
      logger.debug("project_id: #{project_id}")
      @project = Project.find(project_id)

      begin
        # create collectify entry for project
        collectify = @collection.collectifies.create!(:project_id => @project.id)
        
        if @collection.published?
          # if collection is being published for the first time, add a public activity for it
          if @collection.published == false
            @collection.create_activity :create, owner: current_user, primary: true
            @collection.update_attributes(:privacy => "public")
          end

          @project.users.each do |user|
            if user != current_user
              # notify project users that their project has been added to the collection
              @activity = @collection.collectifies.last.create_activity :create, owner: current_user, recipient: user, primary: true
              # create email notifications
              if user.settings(:email).collectify_recipient == true || ( (user.settings(:email).collectify_recipient == false) && (@collection.user == user) )
                NotificationEmailWorker.perform_async(@activity.id, user.id)
              end
            end
          end
        
          if current_user != @collection.user && !@project.users.include?(@collection.user)
            # notify the collection owner that someone else has added a project to the collection
            @activity = @collection.collectifies.last.create_activity :owner_create, owner: current_user, recipient: @collection.user, primary: true
            # create email notifications
            if @collection.user.settings(:email).collectify_recipient == true
              NotificationEmailWorker.perform_async(@activity.id, @collection.user.id)
            end
          end

          @collection.update_attributes(:published=>true)
        end
        @collection.touch

        respond_to do |format|
          format.html { 
            redirect_to collection_path(@collection, :project_id => @project.id)
            flash[:notice] = 'Added ' + @project.title + ' to the collection!' 
          }
          format.json { render :json => @collections }
        end
      rescue ActiveRecord::RecordNotUnique
        respond_to do |format|
          format.html { redirect_to @collection, :alert => 'Project already exists in collection' }
          format.json { render :json => @collections }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @collection, :alert => 'Please enter a valid project URL.' }
        format.json { render :json => @collections }
      end
    end
  end

  def search
    @search_term = params[:search]
    @collections = params[:search_results]

    @project_count = params[:project_count] ||= "0"
    @collection_count = params[:collection_count] ||= "0"
    @user_count = params[:user_count] ||= "0"

    if !@collections.nil?
      @collections = @collections
    else
      @collections = []
    end
    @collections_text = params[:search_text]

    if params[:type] == "Challenges"
      filtered_collections = []
      @collections.each do |collection|
        collection = Collection.find(collection.to_i)
        if collection.challenge == true
          filtered_collections = filtered_collections << collection
        end
      end
      @collections = filtered_collections
    end

    respond_to do |format|
      format.html
      format.js
      format.json { render :json => @collections }
    end
  end

  def update_privacy
    @collection = Collection.find(params[:id])
    Collection.record_timestamps = false
    @collection.update_attributes(:privacy => params[:privacy])
    Collection.record_timestamps = true
    
    respond_to do |format|
      format.html { redirect_to @collection }
    end
  end

  def upload_avatar(file)
    @collection = Collection.find(params[:id])
    @collection.update_attributes(:image => file)
  end

end
