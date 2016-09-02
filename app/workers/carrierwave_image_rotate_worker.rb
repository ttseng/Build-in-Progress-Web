class CarrierwaveImageRotateWorker
	include Sidekiq::Worker 
	
	def perform(image_id)
		if Image.exists?(image_id)
			@image = Image.find(image_id)
			@image.image_path.recreate_versions!
		end
	end	
end