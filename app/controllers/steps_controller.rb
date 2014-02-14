class StepsController < ApplicationController

  before_filter :get_global_variables
  before_filter :authenticate_user!, except: [:index, :show, :show_redirect]

  # :get_project defined at bottom of the file,
  # and takes the project_id given by the routing
  # and converts it to a @project object

  # GET /steps
  # GET /steps.json
  def index    
    
    # set built
    @project.set_built

    respond_to do |format|
      # go directly to the project overview page
      format.html {}
      format.json {}
      format.xml {}
    end
  end

  # GET /steps/1
  # GET /steps/1.json
  def show
    @step = @project.steps.find_by_position(params[:id])
    @images = @project.images.where("step_id=?", @step.id).order("position")

    respond_to do |format|
      format.html # show.html.erb
      format.json { }
    end
  end
  
  # GET /steps/new
  # GET /steps/new.json
  def new
    @step = @project.steps.build(:parent_id=> params[:parent_id])
    authorize! :create, @step    
    @step.build_question

    @step.name = "New Step"
    @step.description = " "
    @step.id = "-1"
    @parentID = params[:parent_id]
    @step.user_id = current_user.id

    respond_to do |format|
      format.html 
      format.json { render :json => @step }
    end
  end

  # GET /steps/1/edit
  def edit
    @step = @project.steps.find_by_position(params[:id])

    if @step.question
      question = @step.question
    else
      question = @step.build_question
    end
    
    if question && !question.decision
      decision = question.build_decision
      decision.description = "I decided to ..."
    end
    
    # update edits with started editing at time
    if Edit.where("user_id = ? AND step_id = ?", current_user.id, @step.id).first
      # user already exists in the step users
      Edit.where("user_id = ? AND step_id = ?", current_user.id, @step.id).first.update_attributes(:started_editing_at => Time.now)
    elsif @project.users.include?(current_user) && !@step.users.include?(current_user)
      # create edit for newly added author that is editing an existing step
      Edit.create(:user_id => current_user.id, :project_id => @project.id, :step_id => @step.id, :started_editing_at => Time.now, :temp => true)
    end

    authorize! :update, @step    
    @step.images.build if @step.images.empty?
    @images = @project.images.where("step_id=?", @step.id).order("position")
    @step.design_files.build if @step.design_files.empty?
  end

  # POST /steps
  # POST /steps.json
  def create
    was_published = @project.published?

    # ensure that the submitted parent_id actually exists
    if !Step.exists?(params[:step][:parent_id].to_f)
      logger.debug "Step doesn't exist!"
      if @project.steps.last
        params[:step][:parent_id] = @project.steps.last.id
      else
        params[:step][:parent_id] = nil
      end
    end

    @step = @project.steps.build(params[:step])
    authorize! :create, @step    
    
    @step.position = @numSteps
    
    respond_to do |format|
      if @step.save

       # update corresponding collections
        @step.project.collections.each do |collection|
          collection.touch
        end
         
         # create an edit entry
         Edit.create(:user_id => current_user.id, :step_id => @step.id, :project_id => @project.id)

        # check whether project is published
        if @project.published? and !@project.published
          if @project.is_remix?
            # create a notification for the parent and original author
            @project.ancestors.each do |ancestor|
              ancestor.users.each do |user|
                if user != current_user
                  @project.create_activity :create, owner: current_user, recipient: user, primary: true
                end
              end
            end
          else
            @project.create_activity :new, owner: current_user, primary: true
          end
          @project.update_attributes(:published=>true)

        elsif @project.published?
          if @project.is_remix?
            # create a notification for the parent and original author
            @project.ancestors.each do |ancestor|
              ancestor.users.each do |user|
                if user != current_user
                  @step.create_activity :create, owner: current_user, recipient: user, primary: true
                end
              end
            end
          else
            @step.create_activity :create, owner: current_user, primary: true
          end
          @project.update_attributes(:published=>true)

        else
          @project.update_attributes(:published=>false)
        end

        @project.set_built

        # update the project updated_at date
        @project.touch

        format.html { 
          @step.update_attributes(:published_on => @step.created_at)

          # update all images with new step id
          new_step_images = @project.images.where("step_id = -1")
          new_step_images.each do |image|
            image.update_attributes(:saved => true)
            image.update_attributes(:step_id => @step.id)
          end

          # update all videos with new step id
          new_step_videos = @project.videos.where("step_id = -1")
          new_step_videos.each do |video|
            video.update_attributes(:saved=>true)
            video.update_attributes(:step_id=> @step.id)
          end

          redirect_to project_steps_path(@project), :flash=>{:createdStep => @step.id}
        }
        format.json { render :json => @step, :status => :created, :location => @step }
      else
        Rails.logger.debug(@step.errors.inspect)
        format.html { render :action => "new" }
        format.json { render :json => @step.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /steps/1
  # PUT /steps/1.json
  def update
    @step = @project.steps.find_by_position(params[:id])
    authorize! :update, @step    

    # update corresponding collections
    @step.project.collections.each do |collection|
      collection.touch
    end
    
    @step.images.each do |image|
      image.update_attributes(:saved => true)
    end

    if params[:step][:published_on_date]
      date = params[:step][:published_on_date]
      logger.debug "date: #{date}"
      time = params[:step][:published_on_time]
      # retain the same seconds as the original published_on date
      time.insert 5, ":" + @step.published_on.strftime("%S")
      # logger.debug "time: #{time}"
      timeZone = params[:step][:timeZone]
      # logger.debug "timeZone: #{timeZone}"
      dateTime = date + " " + time + " " + timeZone
      # logger.debug "dateTime: #{dateTime}"
      dateTime = DateTime.strptime(dateTime, '%m/%d/%Y %I:%M:%S %p %Z')
      # logger.debug "datetime: #{dateTime}"
      
      params[:step][:published_on] = dateTime
      params[:step].delete :'published_on_date'
      params[:step].delete :"published_on_time"
      params[:step].delete :timeZone
    end 

    # update the project updated_at date if it's a remixed step.  maybe check this later to
    # see if the change was due to a change in the original text?  don't know.
    if @project.is_remix?
       @project.touch
    end

    # check whether project is published
    project_published = @project.published?
    if project_published && !@project.published
        # project was just published
        @project.update_attributes(:published=>true)
        if @project.is_remix?
          Rails.logger.debug("creating notifications for ancestors")
          # create a notification for the parent and original author
          @project.ancestors.each do |ancestor|
            ancestor.users.each do |user|
              if current_user != user
                @project.create_activity :create, owner: current_user, recipient: user, primary: true
              end
            end
          end
        end  
    elsif !project_published && @project.published
      # project went back to being unpublished (user removes images, etc.)
      @project.update_attributes(:published=>false)
      if @project.featured
        @project.update_attributes(:featured=> false)
      end
    end

    # remove any design attributes if they contain an ID that doesn't exist (the file had been removed)
    if params[:step][:design_files_attributes]
      params[:step][:design_files_attributes].values.each do |design_file|
        if DesignFile.exists?(design_file['id']) == false
          design_file.delete :id
        end
      end
    end
    
    respond_to do |format|

      if @step.update_attributes(params[:step])
        # clear edit
        edit = Edit.where("user_id = ? AND step_id = ?", current_user.id, @step.id).first
        edit.update_attributes(:started_editing_at => nil)
        if edit.project_id.blank?
          edit.update_attributes(:project_id => @project.id)
        end
        
        # check whether project is published
        if @project.published? and !@project.published
          if @project.is_remix?
            # create a notification for the parent and original author
            @project.ancestors.each do |ancestor|
              ancestor.users.each do |user|
                if user != current_user
                  @project.create_activity :create, owner: current_user, recipient: user, primary: true
                end
              end
            end
          else
            @project.create_activity :new, owner: current_user, primary: true
          end
          @project.update_attributes(:published=>true)

        elsif @project.published?
          if @project.is_remix?
            # create a notification for the parent and original author
            @project.ancestors.each do |ancestor|
              ancestor.users.each do |user|
                if user != current_user
                  @step.create_activity :update, owner: current_user, recipient: user, primary: true
                end
              end
            end
          else
            @step.create_activity :update, owner: current_user, primary: true
          end
          @project.update_attributes(:published=>true)

        else
          # project isn't published, destroy any activities that have to do with the project or steps
          PublicActivity::Activity.where(:trackable_id => @project.id).destroy_all
    
          @project.steps.each do |step|
            PublicActivity::Activity.where(:trackable_id => step.id).destroy_all
          end
          
          @project.update_attributes(:published=>false)
        end

        # check and set built attribute of project
        @project.set_built

        format.html { redirect_to project_steps_path(@project), :notice => 'Step was successfully updated.', :flash => {:createdStep => @step.id} }
        format.json { head :no_content }
      else
        Rails.logger.info(@step.errors.inspect)
        format.html { render :action => "edit" }
        format.json { render :json => @step.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /steps/1
  # DELETE /steps/1.json
  def destroy
    @step = @project.steps.find_by_position(params[:id])
    authorize! :destroy, @step

    PublicActivity::Activity.where(:trackable_id => @step.id).destroy_all

    @step.destroy
    # update positions of subsequent steps
    if @step.position < @steps.count
      for step in @step.position+1..@steps.count
        @steps.where("position" => step)[0].update_attribute(:position, step-1)
      end
    end

    # check whether project is published
    if @project.published?
      @project.update_attributes(:published=>true)
    else
      PublicActivity::Activity.where(:trackable_id => @project.id).destroy_all
      @project.steps.each do |step|
      PublicActivity::Activity.where(:trackable_id => step.id).destroy_all
      end
      @project.update_attributes(:published=>false)
    end

    # check and set built attribute of project
    @project.set_built

    respond_to do |format|
      format.html { redirect_to project_steps_url }
      format.json { head :no_content }
    end
  end

  # Destroy new images
  def destroyNewImages
     respond_to do |format|
        format.html { redirect_to project_steps_url }
      end
  end

  # Sorts steps
  def sort
    params[:step].each_with_index do |id, index|
      Step.update_all({position: index+1}, {id: id})
    end
    render nothing: true
  end

  def create_branch
    @parentStepID = params[:parent]
    respond_to do |format|
      format.js { render :js => "window.location = '#{new_project_step_path(@project, :parent_id=>@parentStepID)}'"}
    end
  end

  # redirect to the edit page for a particular step - called from clicking a step in the 
  # process map while already on the edit page for another step
  def edit_redirect
    @stepID = params[:stepID]
    step = Step.find(@stepID)
    @stepPosition = @steps.where("id"=>@stepID).first.position

    if params[:answered]
      answered = true
    end

    # check if someone else is editing the step
    editing_conflict = false
    editing_conflict_user = ""
    step.edits.pluck(:started_editing_at).each do |edit_date|
      if edit_date != nil && step.edits.where(:started_editing_at => edit_date).first.user != current_user
        editing_conflict = true
        editing_conflict_user = editing_conflict_user + step.edits.where(:started_editing_at => edit_date).first.user.username 
      end
    end
    Rails.logger.info('editing_conflict_user: ' + editing_conflict_user)

    respond_to do |format|
      format.js { 
        if !editing_conflict
          render :js => "window.location = '#{edit_project_step_path(@project, @stepPosition)}?answered=#{answered}'"
        else
          Rails.logger.info("editing conflict")
          render :json => editing_conflict_user
        end
      }
    end
  end

  # redirect to the show page for a particular step
  def show_redirect
    @stepID = params[:stepID]
    @stepPosition = @steps.where("id"=>@stepID).first.position
    respond_to do |format|
      format.js { render :js => "window.location = '#{project_step_path(@project, @stepPosition)}'"}
    end
  end

  # updates the ancestry of a step after the user rearranges ordering in the process map
  def update_ancestry
    @stepID = params[:stepID]
    @stepAncestry = params[:stepAncestry]
    @position = params[:position]
    respond_to do |format|
      @steps.where("id" => @stepID).first.update_attributes(:ancestry => @stepAncestry)
      @steps.where("id" => @stepID).first.update_attributes(:position => @position)
      format.js { render :nothing => true }
    end
  end

  # reset the started_editing_at attribute of an edit table if a user presses the back button
  # out of a step form
  def reset_started_editing
    logger.debug 'in reset started editing'
    user_id = params[:user_id]
    step_id = params[:step_id]
    @project = Project.find(params[:project_id])
    edit = Edit.where("user_id = ? AND step_id = ?", user_id, step_id).first
    
    # if edit was temp, destroy the edit
    if edit
      if edit.temp
        edit.destroy
      else
        edit.reset_started_editing_at
      end
    end

    # delete any uploaded images that weren't saved to a new step
    if step_id == "-1" && params[:back_clicked]=="true"
        Rails.logger.debug("deleting images")
        @project.images.where("user_id = ? AND step_id = ?", user_id, step_id).each do |image|
          CarrierwaveImageDeleteWorker.perform_async(image.id)
        end
    end

    respond_to do |format|
      format.js { render :nothing => true }
    end

  end
  
  private
  # get_project converts the project_id given by the routing
  # into an @project object
  def get_global_variables
    @project = Project.find(params[:project_id])
    @steps = @project.steps.order("position")
    @numSteps = @steps.count
    @ancestry = @steps.pluck(:ancestry) # array of ancestry ids for all steps
    @allBranches # variable for storing the tree structure of the process map
    @users = @project.users # user who created the project
    @authorLoggedIn = user_signed_in? && @users.map(&:username).include?(current_user.username)
  end

end
