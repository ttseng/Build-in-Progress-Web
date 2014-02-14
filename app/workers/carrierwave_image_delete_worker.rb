class CarrierwaveImageDeleteWorker
	include Sidekiq::Worker 

	# delete an image in the background
	# image_id = id of image bto be deleted
	def perform(image_id)
		if Image.exists?(image_id)
			@image = Image.find(image_id)
			@image.destroy
		end
	end
	
end