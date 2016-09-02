class MailPreview < MailView
	def notification_message
		# COMMENT TESTING
		# @activity = PublicActivity::Activity.find(496)

		# FEATURED PROJECT TESTING
		@activity = PublicActivity::Activity.find(487)

		# COLLABORATOR TESTING
		# @activity = PublicActivity::Activity.find(490)

		# FAVORITED TESTING
		# @activity = PublicActivity::Activity.find(489)	

		# COLLECTION TESTING - RECIPIENT
		# @activity = PublicActivity::Activity.find(485)	

		# COLLECTION TESTING - OWNER
		# @activity = PublicActivity::Activity.find(569)		

		# USER FOLLOW TESTING
		# @activity = PublicActivity::Activity.find(491)

		# REMIX TESTING
		# @activity = PublicActivity::Activity.find(492)

		user = @activity.recipient	

		NotificationMailer.notification_message(@activity, user)
	end

	def user_mailer
		user = User.find(1)
		UserMailer.welcome_email(user)
	end

	def survey_mailer
		user = User.find(1)
		SurveyMailer.survey_message(user)
	end
end