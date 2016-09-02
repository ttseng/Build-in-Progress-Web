class HomeController < ApplicationController
  def index

  	if current_user
  		@activities = current_user.followers_activity.where("created_at > ? ", 2.weeks.ago).public_activities.uniq_by(&:trackable_id).first(10)
  	end

    @community_activity_array = Array.new

    questions = Question.where("created_at >?", 1.month.ago).featured.unanswered.limit(10).order("RANDOM()")
    # add to community activity array questions with the format ["question", question_description, project_title, project_id, step_id]
    questions.each_with_index do |question, index|
      if question.step.project.public?
        question_holder = Array.new
        question_holder = ["question", question.description, question.step.project.title, question.step.project.id, question.step.id]
        @community_activity_array << question_holder
      end
    end

    comments = Comment.featured.order('created_at DESC').first(10).shuffle.select {|comment| comment.body.length > 40}
    # add to the community activity array comments with the format ["comment", comment_description, project_title, project_id, step_id]
    comments.each do |comment|
      if comment.commentable.project.public?
        comment_holder = Array.new
        comment_holder = ["comment", comment.body, comment.commentable.project.title, comment.commentable.project.id, comment.commentable.id]
        @community_activity_array << comment_holder
      end
    end

    Rails.logger.debug("@community_activity : #{@community_activity}")

  	@latestProjects = Project.public_projects.order("updated_at DESC").limit(5)
  	@featuredProjects = Project.featured.public_projects.order("featured_on_date DESC").limit(4)
    # @comments = Comment.last(20).where("length(body) > 20").limit(5)

    @newsItems = News.order("created_at DESC").limit(2)

    if @newsItems.length > 0 && @newsItems.first.created_at > 1.week.ago
      @latestNews = @newsItems.first
    end

  end

  def hide_announcement
  	cookies.permanent.signed[:hidden_announcement_id] = params[:id]
  	respond_to do |format|
  		format.html {redirect_to :back}
  		format.js
  	end
  end

  def mobile_request_create
     @message = Message.new(params[:message])
     if @message.valid?
        MobileMailer.new_message(@message).deliver
        redirect_to(mobile_path, :notice => "Your request has been sent!")
      else
         flash.now.alert = "Please fill all fields."
         render :mobile_android
      end
  end

  # dashboard page
  def dashboard
    if current_user && current_user.admin?
      
      respond_to do |format|
        format.html
        format.csv {send_data Step.description_to_csv}
      end
    else 
      redirect_to url_for(:controller => "errors", :action => "show", :code => "401")
    end
  end

end
