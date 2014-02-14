class UserMailer < ActionMailer::Base

  default from: ENV["GMAIL_USERNAME"]

  def welcome_email(user)
  	@user = user
  	@url = ENV["DEV_HOST_URL"]+"/users/login"
  	mail(:to => user.email, :subject => "Welcome to Build In Progress!")
  end
end
