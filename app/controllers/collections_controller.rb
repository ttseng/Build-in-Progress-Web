class CollectionsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :show, :challenges]

  def index
    @collections = Collection.published.order("updated_at DESC").page(params[:collections_page]).per_page(9)

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
    @all_projects = @collection.projects.order("updated_at DESC")
    @projects = @collection.projects.order("updated_at DESC")
    @featured_projects = @collection.projects.featured.order("updated_at DESC");

    respond_to do |format|
      format.html
      format.json { render :json => @collections }
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
  end

  # POST /collections
  # POST /collections.json
  def create
    @collection = current_user.collections.build(params[:collection])

    # set some default values
    numUnnamed = Collection.where("user_id"=>current_user.id).where("name like ?", "%Untitled%").count
    @collection.name = "Untitled-Collection-"+ (numUnnamed+1).to_s()
    @collection.user = current_user
    @collection.challenge = false

    respond_to do |format|
      if @collection.save
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

    respond_to do |format|
      if @collection.update_attributes(params[:collection])
        # create a new activity if the project is now published
        if @collection.published?
          # if collection is being published for the first time, add a public activity for it
          if @collection.published == false
            @collection.create_activity :create, owner: current_user, primary: true
            # create notifications for the projects that are part of the collection
            collectifies = Collectify.where(:collection_id => @collection)
            collectifies.each do |collectify|
              if PublicActivity::Activity.where("trackable_type = ? AND trackable_id = ?", "Collectify", collectify.id).blank? 
                  # add public activity
                  collectify.create_activity :create, owner: current_user, recipient: collectify.project.user, primary: true
                  if current_user != @collection.user and @collectify.project.user != @collection.user
                    collectify.create_activity :owner_create, owner: current_user, recipient: @collection.user, primary: true
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
          end

          @project.users.each do |user|
            @collection.collectifies.last.create_activity :create, owner: current_user, recipient: user, primary: true
          end
        
          if current_user != @collection.user and !@project.users.include?(@collection.user)
            @collection.collectifies.last.create_activity :owner_create, owner: current_user, recipient: @collection.user, primary: true
          end

          @collection.update_attributes(:published=>true)
        end
        @collection.touch

        respond_to do |format|
          format.html { redirect_to @collection }
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

end
