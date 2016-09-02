class NotificationEmailWorker
	include Sidekiq::Worker 

	# delete an image in the background
	# image_id = id of image bto be deleted
	def perform(activity_id, user_id)
		if PublicActivity::Activity.exists?(activity_id) && User.exists?(user_id)
			@activity = PublicActivity::Activity.find(activity_id)
			@user = User.find(user_id)
			NotificationMailer.notification_message(@activity, @user).deliver
		end
	end
	
end