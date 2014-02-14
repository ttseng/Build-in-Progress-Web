# upload images to Amazon S3 in the background

class UploadImageWorker
	include Sidekiq::Worker
	sidekiq_options retry: false

	def perform(remix_project_id, original_project_id)
		Rails.logger.debug("remix_project_id #{remix_project_id}")
		Rails.logger.debug("original_project_id #{original_project_id}")

		remix_project = Project.find(remix_project_id)
		original_project = Project.find(original_project_id)

		original_project_steps = original_project.steps.order(:position)
        remix_project_steps = remix_project.steps.order(:position)

        # SECOND: replace step images
        # map new images with old images
        image_hash = Hash.new # format: original_image_id: new_image_id
        remix_project.steps.order(:position).each_with_index do |step, step_index|
        	step.images.order(:position).each.with_index do |image, image_index|
        		image_hash[original_project.steps.order(:position)[step_index].images.order(:position)[image_index].id] = image.id
        	end
        end

		remix_project.steps.order(:position).each_with_index do |step, step_index|
			step.videos.each do |video|
            	video.update_attributes(:project_id => remix_project.id)
            	# find the correct image id for the video
            	video.update_attributes(:image_id => image_hash[video.image_id])
   	       	end
	        step.images.order(:position).each_with_index do |image, index|
	            image.update_attributes(:project_id=>remix_project.id)
	            
	            # find the correct video id for image
	            if image.has_video?
	           		image.update_attributes(:video_id => Video.where(:image_id=>image.id).first.id)
	           	end

	            original_image_path = original_project_steps[step_index].images.order(:position)[index].image_path.to_s
	            # change https of original project image url to http
	            original_image_path = "http#{original_image_path[5, original_image_path.length]}"
	            image.update_attributes(:remote_image_path_url=> original_image_path)
          	end
        end
     
	end
end