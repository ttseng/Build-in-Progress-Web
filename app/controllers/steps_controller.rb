class StepsController < ApplicationController

  before_filter :get_global_variables
  before_filter :authenticate_user!, except: [:index, :show, :show_redirect, :mobile]
  before_filter :check_tree_width, only: :mobile

  # :get_project defined at bottom of the file,
  # and takes the project_id given by the routing
  # and converts it to a @project object

  # GET /steps
  # GET /steps.json
  def index    
    authorize! :read, @project  
    @stepIDs = @project.steps.not_labels.order("published_on").pluck(:id)

    # fix step position and ancestry if there's an error
    if @project.steps.where(:position => -1).present?
      Rails.logger.info("FIXING STEP POSITIONS AND ANCESTRY")
      start_position = @project.steps.order(:position).last.position
      @project.steps.where(:position => -1).order("created_at").each do |step|
        last_step = @project.steps.where(:position => start_position).first
        step.update_attributes(:ancestry => last_step.ancestry + "/" + last_step.id.to_s)
        step.update_attributes(:position => start_position+1)
        start_position = start_position + 1
      end
    end
    
    respond_to do |format|
      # go directly to the project overview page
      format.html 
      format.json
      format.xml 
    end
  end

  # GET /steps/mobile
  def mobile
    @stepIDs = @project.steps.not_labels.order("published_on").pluck(:id)
    respond_to do |format|
        format.html{
           if @project.users.include?(User.where(:authentication_token => params[:auth_token]).first)  || (current_user && @project.users.include?(current_user)) || (current_user && current_user.admin?)
           else
            redirect_to errors_unauthorized_path
           end
        }        
    end
  end

  # GET /steps/1
  # GET /steps/1.json
  def show
    authorize! :read, @project
    @step = @project.steps.find_by_position(params[:id])
    @images = @project.images.where("step_id=?", @step.id).order("position")

    respond_to do |format|
      format.html
      format.json 
      format.xml
    end
  end
  
  def new
    begin
      @step = @project.steps.build(:parent_id=> params[:parent_id].to_i)
    rescue Exception
      @step = @project.steps.build
    end

    authorize! :create, @step    
    @step.build_question

    if params[:label] == "false"
      @step.name = "New Step"
      @step.description = " "
    else
      @step.name = "New Branch Label"
    end

    @step.id = "-1"
    @parentID = params[:parent_id]
    Rails.logger.debug("@parentID: #{@parentID}")
    @step.user_id = current_user.id

    respond_to do |format|
      format.html 
      format.json { render :json => @step }
    end
  end


  # GET /steps/1/edit
  def edit
      @step = @project.steps.find_by_position(params[:id])
      authorize! :edit, @step

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

    # ensure that the submitted parent_id actually exists
    if !Step.exists?(params[:step][:parent_id].to_i)
      logger.debug "Step doesn't exist!"
      if @project.steps.last
        params[:step][:parent_id] = @project.steps.last.id
      else
        params[:step][:parent_id] = nil
      end
    end

    if params[:step][:pin] && params[:step][:pin].empty?
      params[:step][:pin] = nil
    end

    @step = @project.steps.build(params[:step])
    authorize! :create, @step    

    if params[:step][:position]
      @step.position = params[:step][:position]
    else
      @step.position = @numSteps
    end
    
    respond_to do |format|
      if @step.save

       # update corresponding collections
        @step.project.collections.each do |collection|
          collection.touch
        end
         
         # create an edit entry
         Edit.create(:user_id => current_user.id, :step_id => @step.id, :project_id => @project.id)

        # check whether project is published
        if @project.public? || @project.privacy.blank?
          @project.set_published(current_user.id, @project.id, @step.id)
        end

        @project.set_built

        # update the project updated_at date
        @project.touch

        # update the user last_updated_at date
        current_user.touch

        @step.update_attributes(:published_on => @step.created_at)

        # create a public activity for any added question
        if @step.question
          Rails.logger.debug("created new question")
          @step.question.create_activity :create, owner: current_user, primary: true
        end

        # log the creation of a new step
        @project.delay.log

        format.html { 

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

          # push project to village if it doesn't already exist
          if @project.village_id.blank? && current_user.from_village? && @project.public? && !access_token.blank?
            create_village_project
          elsif !@project.village_id.blank? && !access_token.blank?
            update_village_project
          end
          
          redirect_to project_steps_path(@project), :flash=>{:createdStep => @step.id}
          
        }
        
        format.json { render :json => @step }
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

    # remove question if question description is empty
    if params[:step][:question_attributes] && params[:step][:question_attributes][:description].length == 0 && @step.question
      @step.question.destroy
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

    # update the project 
    @project.touch

    # update the user last updated date
    current_user.touch

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
      
        # clear label color if user didn't select color
        if @step.label == false
          @step.update_column("label_color", nil)
        end

        # clear edit
        edit = Edit.where("user_id = ? AND step_id = ?", current_user.id, @step.id).first
        edit.update_attributes(:started_editing_at => nil)
        if edit.project_id.blank?
          edit.update_attributes(:project_id => @project.id)
        end
        
        # check whether project is published
        if @project.public? || @project.privacy.blank?
          @project.set_published(current_user.id, @project.id, @step.id)
        end

        # check and set built attribute of project
        @project.set_built

        # create a public activity for any questions associated with the step if it doesn't already exist
        if @step.question && !PublicActivity::Activity.where(:trackable_type => "Question").where(:trackable_id => @step.question.id).exists?
          @step.question.create_activity :create, owner: current_user, primary: true
        end

        # create project on the village if the current user is a village user and the project doesn't already exist
        if @project.village_id.blank? && current_user.from_village? && !access_token.blank? && @project.public?
          create_village_project
        elsif !@project.village_id.blank? && !access_token.blank?
          update_village_project
        end

        format.html { 
            redirect_to project_steps_path(@project), :notice => 'Step was successfully updated.', :flash => {:createdStep => @step.id} 
        }
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
    @step = Step.find(params[:step_id])
    authorize! :destroy, @step

    if @step.ancestry=="0" && @project.steps.where(:ancestry => @step.id.to_s).length > 1
      # can't delete root!
      respond_to do |format|
        format.html {
          flash[:error] = "Can't delete the root of your project!"
          redirect_to project_steps_url
        }
      end     
    else
      if @step.ancestry == "0"
        @project.steps.where("id !=?", @step.id.to_s).each do |step|
          if step.ancestry == @step.id.to_s
            step.update_attributes(:ancestry => "0")
          else
            step.update_attributes(:ancestry => step.ancestry.gsub(@step.id.to_s+"/", ""))
          end
        end
      end

      PublicActivity::Activity.where(:trackable_id => @step.id).destroy_all
      if @step.question
        PublicActivity::Activity.where(:trackable_id => @step.question.id).destroy_all
      end    

      # destroy any news items associated with it
      News.where(:step_id => @step.id).each do |news_item|
        news_item.destroy
      end

      @step.destroy
      
      # update positions of subsequent steps
      if @step.position < @steps.count
        for step in @step.position+1..@steps.count
          if @steps.where("position" => step).exists?
            @steps.where("position" => step)[0].update_attribute(:position, step-1)
          end
        end
      end

      # check whether project is published
      if @project.public?
        @project.set_published(current_user.id, @project.id, nil)
      end

      # check and set built attribute of project
      @project.set_built

      @project.delay.log

      respond_to do |format|
        format.html { redirect_to project_steps_url }
        format.json { head :no_content }
      end
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
    @project = Step.find(@parentStepID).project
    authorize! :create_branch, @project
    @label = params[:label]
    respond_to do |format|
      format.js { render :js => "window.location = '#{new_project_step_path(@project, :parent_id=>@parentStepID, :label => @label)}'"}
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

    Rails.logger.info('checking editing conflict')

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
          render :js => "window.location='#{edit_project_step_path(@project, @stepPosition)}?answered=#{answered}'"
        else
          render :json => editing_conflict_user
        end
      }
    end
  end

  # redirect to the show page for a particular step
  def show_redirect
    @stepID = params[:stepID]
    @step = @steps.where("id"=>@stepID).first
    if @step.present?
      @stepPosition = @step.position
      respond_to do |format|
        format.js { render :js => "window.location = '#{project_step_path(@project, @stepPosition)}'"}
      end
    else
      respond_to do |format|
        format.js { render :nothing => true}
      end
    end
  end

  # get the position of a step (used for redirecting to edit / show step pages)
  def get_position
    @step = Step.find(params[:stepID])
    if @step
      position = @step.position
    end
    respond_to do |format|
      format.js{
        render :js => position
      }
    end
  end

  # update_ancestry: given an array of the steps in a project, update the position and ancestry of all steps
  # the expected format is {step_id: [position,ancestry]}
  def update_ancestry
    Step.record_timestamps = false
    steps = params[:stepMapArray]
    
    # Rails.logger.debug("steps: #{steps}")
    steps.each do |step|
      id = step[0].to_i
      position = step[1][0].to_i
      ancestry = step[1][1]      

      # Rails.logger.debug("id: #{step[0]} position: #{step[1][0]} ancestry: #{step[1][1]}")
      if Step.exists?(:id => id)
          Step.find(id).update_attributes(:position => position)
          Step.find(id).update_attributes(:ancestry => ancestry)
      end
    end

    Step.record_timestamps = true
    respond_to do |format|
      format.js {render :nothing => true}
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

    respond_to do |format|
      format.js { render :nothing => true }
    end

  end

  # create a project on the village using an iframe with the embed page
  def create_village_project
    iframe_src = "<iframe src='" + root_url.sub(/\/$/, '') + embed_project_path(@project) + "' width='575' height='485'></iframe><p>This project created with <b><a href='" + root_url + "'>#{ENV["APP_NAME"]}</a></b> and updated on " + @project.updated_at.strftime("%A, %B %-d at %-I:%M %p") +"</p>"
    iframe_src = iframe_src.html_safe.to_str
    village_user_ids = @project.village_user_ids
    response = access_token.post("/api/projects", params: {project: {name: @project.title, project_type_id: 15, source: "original", description: iframe_src, thumbnail_file_id: 769508, user_ids: village_user_ids} })
    village_project_id = response.parsed["project"]["id"]
    @project.update_attributes(:village_id => village_project_id)
  end
  
  # update a project on the village
  def update_village_project
    iframe_src = "<iframe src='" + root_url.sub(/\/$/, '') + embed_project_path(@project) + "' width='575' height='485'></iframe><p>This project created with <b><a href='" + root_url + "'>#{ENV["APP_NAME"]}</a></b> and updated on " + @project.updated_at.strftime("%A, %B %-d at %-I:%M %p") +"</p>"
    iframe_src = iframe_src.html_safe.to_str
    village_user_ids = @project.village_user_ids
    response = access_token.put("/api/projects/" + @project.village_id.to_s, params: {project: {name: @project.title, description: iframe_src, user_ids: village_user_ids}})
  end

  private

  # get_project converts the project_id given by the routing
  # into an @project object
  def get_global_variables
    @project = Project.where(:id => params[:project_id])
    if @project.present?
      @project = @project.first
      @steps = @project.steps.order("position")
      @numSteps = @steps.count
      @ancestry = @steps.pluck(:ancestry) # array of ancestry ids for all steps
      @allBranches # variable for storing the tree structure of the process map
      @users = @project.users # user who created the project
      @authorLoggedIn = user_signed_in? && @users.map(&:username).include?(current_user.username)
    else
      # redirect to error page - project no longer exists
      render :file => "errors/404.html",  :status => 404
    end
  end

  def check_tree_width
    redirect_to(tree_width: @project.tree_width, auth_token: params[:auth_token]) unless params[:tree_width].present?
  end

end
