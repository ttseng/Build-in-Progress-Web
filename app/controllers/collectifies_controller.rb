class CollectifiesController < ApplicationController
	before_filter :authenticate_user!

	def create
	end
	
	def destroy
		@collection = Collection.find(params[:id])
		@project = Project.find(params[:project_id])
		@collectify = Collectify.where(:project_id=>@project.id, :collection_id=>@collection)
		PublicActivity::Activity.where(:trackable_id => @collectify).destroy_all 

    	@collection.remove!(@project)
    	Rails.logger.debug "collectify collection: #{@collection.id}"
    	Rails.logger.debug "@collection.published?  #{@collection.published?}"
    	Rails.logger.debug "@collection.published  #{@collection.published}"
    	if !@collection.published? 
    		@collection.update_attributes(:published=>false)
    		# remove public activities for that collection
    		Rails.logger.debug "removing public activity for collection #{@collection.id}"
    		PublicActivity::Activity.where(:trackable_id => @collection).destroy_all
    	end
    	redirect_to @collection
	end
end
