class CarrierwaveImageUploaderWorker
	include Sidekiq::Worker 

	# create version of image directly uploaded to s3
	# image_id = id of image being updated
	# s3_url = 'url' of direct image (note: contains %2F rather than spaces)
	def perform(image_id, s3_url)
		if Image.exists?(image_id)
			@image = Image.find(image_id)
			Rails.logger.debug("uploading image #{@image.id} in background task")
			@image.remote_image_path_url = s3_url
			@image.update_column(:rotation, nil)
		    @image.save
		end
	end
	
end