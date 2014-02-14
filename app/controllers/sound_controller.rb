class SoundsController < ApplicationController
	before_filter :authenticate_user!, except: [:embed_code]
	def create
		@project = Project.find(params[:sound][:project_id])
		@sound = Sound.create(params[:sound])

		# create a new image record using the thumbnail image
		thumbnail = @sound.thumbnail_url
		position = @project.images.where(:step_id=>@sound.stepd_id).count
		@image = Image.new(:step_id=>@sound.step_id, :image_path=>"", :project_id=>@sound.project_id,
			:saved=>true, :position=> position, :sound_id=> @sound.id)
		@image.update_attributes(:remote_image_path_url=>thumbnail)
		@image.save

		respond_to do |format|
			if @sound.save
				@sound.update_attributes(:image_id=>@image.id)
				format.js {render 'images/create'}
			else
				Rails.logger.info(@sound.errors.inspect)
				format.json { render :json => @video.errors, :status => :unprocessable_entity }
			end
		end
	end
end
