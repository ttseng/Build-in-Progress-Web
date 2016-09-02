class UserMailer < ActionMailer::Base
  include Roadie::Rails::Automatic

  default from: ENV["GMAIL_USERNAME"]

  def welcome_email(user)
  	@user = user
  	@url = ENV["DEV_HOST_URL"]+"/users/login"
  	mail(:to => user.email, :subject => "Welcome to #{ENV["APP_NAME"]}!")
  end
end
