class VideoUploadWorker
	include Sidekiq::Worker 

	# upload and process a new video object
	# image_id = id of image being updated
	# s3_url = 'url' of direct image (note: contains %2F rather than spaces)
	def perform(project_id, step_id, video_path, user_id, embed_path, saved, mobile)
		videoObj = Hash.new
		if video_path
			videoObj["video_path"]=video_path
		elsif embed_url
			videoObj["embed_url"]=VideoInfo.get(embed_path).embed_url

		end
		videoObj["project_id"]=project_id
		videoObj["step_id"]=step_id
		videoObj["saved"]=true
		videoObj["user_id"]=user_id
		@video = Video.create(videoObj)
		@project = Project.find(project_id)		

		# create the video image thumbnail
		image_position = @project.images.where(:step_id => step_id).count

		if @video.embedded?
			thumbnail = @video.thumb_url
			@video.update_attributes(:thumbnail_url => thumbnail)

			@image = Image.new(:step_id => @video.step_id, :image_path => "", :project_id => @video.project_id, 
				:user_id => current_user.id, :saved => true, :position => image_position, :video_id => @video.id)
			@image.update_attributes(:remote_image_path_url => thumbnail)
			@image.save
		else
			# create a new image record using the thumbnail generated from ffmpegthumbnailer
			@image = Image.new(:step_id=>@video.step_id, :image_path=> "", :project_id=>@video.project_id, 
				:user_id => current_user.id, :saved=> true, :position=>image_position, :video_id=> @video.id)
      		@image.update_attributes(:remote_image_path_url => @video.video_path_url(:thumb))
            @image.save
		end

		if @video.save
			@video.update_attributes(:image_id => @image.id)
			@video.project.touch

			if !mobile
			else
			end
			#render image create
		end
	
	end
	
end