class NotificationMailer < ActionMailer::Base
  include Roadie::Rails::Automatic
  default from: ENV["GMAIL_USERNAME"]

  def notification_message(activity, user)
    # Rails.logger.debug("=========IN NOTIFICAFTION MESSAGE========")
  	@user = user
  	@activity = activity

  	# generate subject of message based on activity type
  	if @activity.is_comment?
  		# username commented on project_title
      # Rails.logger.debug("=========CREATE COMMENT MAILER========")
  		subject = @activity.trackable.user.username + ' commented on ' + @activity.trackable.commentable.project.title
      @type = "comment"
  	elsif @activity.is_featured?
  		# project_title has been featured!
      # Rails.logger.debug("=========CREATE FEATURED MAILER========")
  		subject = @activity.trackable.title + ' has been featured!'
      @type = "featured"
  	elsif @activity.is_added_as_collaborator?
      # Rails.logger.debug("=========CREATE COLLABORATOR MAILER========")
  		# adder_username added you as a collaborator on project_title
  		subject =  @activity.owner.username + " added you as a collaborator on " + @activity.trackable.title
      @type = "collaborator"
  	elsif @activity.is_favorited?
      # Rails.logger.debug("=========CREATE FAVORITED MAILER========")
  		# project_title was favorited by username
  		subject = @activity.trackable.user.username + ' favorited ' + @activity.trackable.project.title
      @type = "favorited"
  	elsif @activity.is_added_to_collection?
      # Rails.logger.debug("=========CREATE COLLECTION MAILER - RECIPIENT========")
  		# project_title was added to the collection collection_name
  		subject = @activity.trackable.project.title + ' was added to the collection ' + @activity.trackable.collection.name
      @type = "collectify_recipient"
    elsif @activity.is_updated_collection?
      # Rails.logger.debug("=========CREATE COLLECTION MAILER - OWNER========")
      # project_title was added to the collection collection_name
      subject = @activity.owner.username + ' updated the collection ' + @activity.trackable.collection.name
      @type = "collectify_owner"            
  	elsif @activity.is_followed?
      # Rails.logger.debug("=========CREATE FOLLOWED MAILER========")
  		# username followed you
  		subject = @activity.owner.username + ' followed you'
      @type = "followed"
  	elsif @activity.is_remixed?
      # Rails.logger.debug("=========CREATE REMIX MAILER========")
  		# username remixed project_title
  		subject = @activity.owner.username + ' remixed ' + @activity.trackable.root.title
      @type = "remixed"
  	end

  	# Rails.logger.debug("notification subject: #{subject}")
  	
  	mail(to: @user.email, subject: subject)
  end

end
