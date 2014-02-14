class NotificationsMailer < ActionMailer::Base
  default from: "noreply@buildinprogress.com"
  default to: ENV["GMAIL_USERNAME"]

  def new_message(message)
  	@message = message
  	mail(:subject => "[Build in Progress - #{message.type}] #{message.subject}")
  end
end
