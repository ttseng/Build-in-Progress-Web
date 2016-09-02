class ContactController < ApplicationController
  
  def new
    @message = Message.new
  end

  def create
    @message = Message.new(params[:message])
    
    if @message.valid?
      ContactMailer.new_message(@message).deliver
      if @message.project_url
        # message sent from project page - return a response
        respond_to do |format|
          format.json {
            Rails.logger.debug("SENDING RESPONSE JSON")
            render :json => "Thanks for your feedback!"
            # redirect_to(request.referrer, :notice => "Thanks for your feedback!")
          }
        end

      else
        redirect_to(root_path, :notice => "Thanks for your feedback!")
      end
    else
      flash.now.alert = "Please fill all fields."
      render :new
    end
  end

end
