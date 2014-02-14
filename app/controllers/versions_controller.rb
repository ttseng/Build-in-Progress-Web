class VersionsController < ApplicationController
	
	def revert
		@projectID = params[:id]
		logger.debug("@projectID: #{@projectID}")
		@steps = Step.where("project_id"=>@projectID)
		logger.debug("@steps.length: #{@steps.length}")
		
		@steps.each do |step|
			logger.debug("step.id: #{step.id}")
			logger.debug("step.name: #{step.name}")
			logger.debug("step.position: #{step.position}")
			@step = step.versions.scoped.last
			if @step != nil
				@version = Version.find(@step)
				if @version.reify
					@version.reify.save!
				end
			end
		end

		redirect_to :back 
	end

end
