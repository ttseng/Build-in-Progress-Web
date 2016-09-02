class VideosController < ApplicationController
  respond_to :html, :xml, :json
  before_filter :authenticate_user!, except: [:embed_code]

  # example request URL:
  # /videos/embed_code.json?url=http://www.youtube.com/watch?v=1L-UotMNAHU
  # get back json response with the embed code for the video!
  
  def embed_url
    video_url = params[:video_url]
    video = VideoInfo.get(video_url)
    if(video)
      embed_url = video.embed_url
      vid = Video.new(:embed_url=> embed_url)
      # check that the video is valid
      render :json => vid.as_json(:methods => :embed_code)
    else
      render :json => false
    end
  end

  # from embed code, extract the embed url
  def get_embed_url(embed_code)
    regex =  /(youtu\.be\/|youtube\.com\/(watch\?(.*&)?v=|(embed|v)\/))([^\?&"'>]+)/
    url = "" #placeholder url

    if embed_code.match(regex) != nil && embed_code.include?("iframe")
      youtube_id = embed_code.match(regex)[5]
      Rails.logger.debug "youtube_id : #{youtube_id}"
      url = "http://www.youtube.com/embed/"+youtube_id
    end
    return url
  end

  # GET /videos
  def index
    @videos = Video.find(:all)    
  end

  # POST /videos
  def create
    if params[:video]
      if !params[:video][:embed_url].blank?
         # convert video_url to embed_url
         video_url = params[:video][:embed_url]
         params[:video][:embed_url] = VideoInfo.get(video_url).embed_url
      end
      @project = Project.find(params[:video][:project_id])
      @video = Video.new(params[:video])
      authorize! :create, @video
      @video.save
    else
      videoObj = Hash.new
      videoObj["project_id"]=params[:project_id]
      videoObj["step_id"]=params[:step_id]
      videoObj["saved"]=true
      videoObj["video_path"]=params[:video_path]
      videoObj["user_id"]=params[:user_id]
      @video = Video.create(videoObj)
      @project = Project.find(params[:project_id])
    end

    image_position = @project.images.where(:step_id=>@video.step_id).count # set the image position of the added thumbnail

    if @video.embedded?
      # get the thumbnail image
      thumbnail = @video.thumb_url
      @video.update_attributes(:thumbnail_url => thumbnail)

      # create a new image record for the thumbnail      
      @image = Image.new(:step_id=>@video.step_id, :image_path=> "", :project_id=>@video.project_id, :user_id => current_user.id, :saved=> true, :position=>image_position, :video_id=> @video.id)
      @image.update_attributes(:remote_image_path_url => thumbnail)
      @image.save
    else
      # create a new image record using the thumbnail generated from ffmpegthumbnailer
      @image = Image.new(:step_id=>@video.step_id, :image_path=> "", :project_id=>@video.project_id, :user_id => current_user.id, :saved=> true, :position=>image_position, :video_id=> @video.id)
      Rails.logger.debug("creating thumbnail with image #{@video.video_path_url(:thumb)}")
      @image.update_attributes(:remote_image_path_url => @video.video_path_url(:thumb))
      @image.save
    end

    respond_to do |format|
      if @video.save!  
        # add thumbnail image id to video
        @video.update_attributes(:image_id=>@image.id)

        # update project
        @video.project.touch

        format.js {
          if params[:video]
            render 'images/create'
          else
            video_info = @video.id, @video.video_path_url, @video.image.image_path_url(:preview)
            logger.debug("sending JSON video id #{video_info.to_json}")
            render :json => video_info.to_json
          end
        }
        
      else
        Rails.logger "video save failed"
        Rails.logger.info(@video.errors.inspect)
        format.json { render :json => @video.errors, :status => :unprocessable_entity }
      end
    end
  end

  # create_mobile
  # create video object from mobile - receives direct uploaded AWS video from the parameters s3_video_url
  def create_mobile
     videoObj = Hash.new
     videoObj["project_id"]=params[:project_id]
     videoObj["step_id"]=params[:step_id]
     videoObj["saved"]=true
     videoObj["user_id"]=params[:user_id]
     @video = Video.create(videoObj)
     @video.update_attributes(:remote_video_path_url => params[:s3_video_url])
     @video.save

     # create thumbnail image
     @project = Project.find(params[:project_id])
     image_position = @project.images.where(:step_id=>@video.step_id).count 
     @image = Image.new(:step_id=>@video.step_id, :image_path=> "", :project_id=>@video.project_id, :user_id => current_user.id, :saved=> true, :position=>image_position, :video_id=> @video.id)
     logger.debug("creating video thumbnail with path #{@video.video_path_url(:thumb)}")
     @image.update_attributes(:remote_image_path_url => @video.video_path_url(:thumb))
     @image.save
     @video.update_attributes(:image_id => @image.id)
     @video.project.touch

     # delete the temporary video on s3
     s3 = AWS::S3.new(:access_key_id => ENV['AWS_ACCESS_KEY_ID'], :secret_access_key => ENV['AWS_ACCESS_KEY'])
     video_path = "uploads/" + params[:s3_video_url].split('/').last
     logger.debug("AWS path to video file to delete: #{video_path}")
     s3.buckets[ENV['AWS_BUCKET']].objects.with_prefix(video_path).delete_all

     respond_to do |format|         
         format.js{
          video_info = @video.image.id, @video.video_path_url, @video.image.image_path_url(:preview)
          render :json => video_info.to_json
        }
     end

  end

  # DELETE /videos/1
  def destroy
    @video = Video.find(params[:id])
    authorize! :destroy, @video
    @video.destroy
  end


end
