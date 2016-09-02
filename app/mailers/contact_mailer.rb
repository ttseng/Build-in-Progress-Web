class ContactMailer < ActionMailer::Base
  default from: "noreply@buildinprogress.com"
  default to: "buildinprogressllk@gmail.com"

  def new_message(message)
  	if message.user
      if message.project_url
        mail(:subject => "[#{message.type}] #{message.subject}", :body => "#{message.body} \nfrom user #{message.user} (#{User.where(:username=>message.user).first.email}) on project #{message.project_url}")
      else
        mail(:subject => "[#{message.type}] #{message.subject}", :body => "#{message.body} from user #{message.user} (#{User.where(:username=>message.user).first.email})")
      end
  	else
		mail(:subject => "[#{message.type}] #{message.subject}", :body => "#{message.body}")
  	end
  	
  end

end
