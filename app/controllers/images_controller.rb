class ImagesController < ApplicationController
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  include CarrierWave::MiniMagick

  before_filter :authenticate_user!

  # GET /images
  def index
    @images = Image.find(:all)    
  end

  # GET /images/1
  def show
    @image = Image.find(params[:id])
  end

  # GET /images/new
  def new
    @image = Image.new
  end

  # POST /images
  def create
    if params[:image]
      imageObj = Hash.new
      imageObj["project_id"]=params[:project_id].to_f
      imageObj["step_id"]=params[:step_id].to_f
      imageObj["saved"]=false
      imageObj["user_id"]=params[:user_id].to_f
      s3_image_url = params[:image][:image_path]
      Rails.logger.debug("s3_image_url: #{s3_image_url}")
      image_url = s3_image_url.gsub('%2F', '/')
      imageObj["s3_filepath"] = image_url
      @image = Image.new(imageObj)
      authorize! :create, @image
      @image.save
      # now that the temp image is saved, set the image path url
      @image.delay.upload_image
    else # image sent from android app
      imageObj = Hash.new
      imageObj["project_id"]=params[:project_id]
      imageObj["step_id"]=params[:step_id]
      imageObj["saved"]=false
      imageObj["image_path"]=params[:image_path]
      imageObj["user_id"]=params[:user_id]
      @image = Image.create(imageObj)
    end

    if @image.step_id != -1
      # adding image to existing step
      num_step_images = Step.find(@image.step_id).images.count
    else
      num_step_images =  Project.find(@image.project_id).images.where("step_id = ? AND user_id = ?", -1, @image.user_id).count
    end

    @image.update_attributes(:position => num_step_images-1)
  
    # update the corresponding project
    @image.project.touch

    respond_to do |format|
      if request.format.xhr?
        format.js
      else
        image_info = @image.id, @image.s3_filepath
        format.html{ render :json => image_info.to_json}
        format.js { render :json => image_info.to_json}
        format.xml { render :json => image_info.to_json}
      end
    end

  end
  

  # GET /images/1/edit
  def edit
    @image = Image.find(params[:id])
  end

  # rotate an image 90 degrees counter clockwise
  def rotate
    @image = Image.find(params[:id])
    @rotation = params[:rotation]
    if @rotation == "8"
      @rotation = 270
    end
    @image.update_column(:rotation, @rotation)
    respond_to do |format|
       format.js { render :nothing => true }
    end
  end

  # PUT /images/1
  def update
    @image = Image.find(params[:id])
    @project = @image.project_id
    @step = @image.step_id
    @position = Step.find_by_id(@step).position

      if @image.update_attributes(params[:image])
        redirect_to edit_project_step_url(@project, @position), notice: "image was successfully updated."
      else
        render :edit
      end
  end

  # DELETE /images/1
  def destroy
    if(params[:s3_filepath])
      # cleaned_filepath = params[:s3_filepath].gsub('%2F', '/').gsub(" ", "+")
      # @image = Image.where(:s3_filepath => cleaned_filepath).first
      @image = Image.where(:s3_filepath => params[:s3_filepath]).first
    else
      @image = Image.find(params[:id])    
      authorize! :destroy, @image

      # delete any references to this image
      if !@image.is_remix_image?
        @image.remix_images.each do |image|
          if image.has_video?
            image.video.destroy
          end
          image.destroy
        end
      end

      if @image.step_id != -1
        if @image.position < @image.step.images.count
          @image.step.images.order(:position).where("position > ?", @image.position).each do |image|
            Rails.logger.debug "image position before: #{image.position}"
              image.update_attributes(:position => image.position-1)
            Rails.logger.debug "image position after: #{image.position}"
          end
        end
      else
        remix_images = @image.project.images.where(:step_id=>-1)
        if @image.position < remix_images.count
          remix_images.order(:position).where("position > ? ", @image.position).each do |image|
            image.update_attributes(:position=> image.position-1)
          end
        end
      end

      # set project to new unlisted if necessary
      if @image.project.images.count == 0
        @image.project.update_attributes(:privacy => nil)
      end
    end

    # destroy original image
    @image.destroy

    respond_to do |format|
      format.js {render :nothing => true}
    end
  end

   # Sorts images
  def sort
    params[:image].each_with_index do |id, index|
      Image.update_all({position: index}, {id: id})
    end
    render nothing: true
  end

  # finds the id of an image based on the s3 path url
  def find_image_id
    s3_url = params[:s3_url]
    image = Image.where("s3_filepath = ? ", s3_url).first
    if image != nil
      Rails.logger.debug("image.id : #{image.id}")
    end
    respond_to do |format|
      format.js { 
        if image != nil
          render :json => image.id 
        else
          render :nothing => true
        end
      }
    end
  end

  # export images
  def export
    image = Image.find(:params[:id])
    send_file(image.image_path_url, :type => 'image/jpeg')
  end


end
