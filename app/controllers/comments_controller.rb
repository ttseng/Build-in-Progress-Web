class CommentsController < ApplicationController

  before_filter :authenticate_user!
  
  def create
    @project = Project.find(params[:project_id])
    @commentText = params[:comment][:body]
    @user = current_user
    @comment = Comment.build_from(@project.steps.find(params[:step_id]), @user.id, @commentText)
    
    respond_to do |format|
      if @comment.save
        # create an activity for each author of the project
        @project.users.each do |user|
          if user != current_user
            @activity = @comment.create_activity :create, owner: current_user, recipient: user, primary: true 
            # send an email to the user
            Rails.logger.debug("attempting to send email notification to #{user.username}")
            if user.settings(:email).comments == true
              Rails.logger.debug("sending comment email notification")
              NotificationEmailWorker.perform_async(@activity.id, user.id)
            end
          end
        end
        
        # create an array containing all unique users that have previously commented on this step
        comment_users = Array.new
        @comment.commentable.comment_threads.each do |existing_comment|
          if ((comment_users.include? existing_comment.user_id) == false) && (existing_comment.user_id != @comment.user_id) && (!@project.users.include? existing_comment.user)
            comment_users.push(existing_comment.user_id)
          end
        end

        # create an activity for all other people that have commented on this step
        comment_users.each do |user_id|
           @comment.create_activity :create, owner: current_user, recipient: User.find(user_id), primary: false
        end

        comments_id = "comments_" + @comment.commentable_id.to_s
        comment_id = "comment_" + @comment.id.to_s
        format.html {
          redirect_to project_steps_path(@project, :step => @comment.commentable.id, :comment_id=> @comment.id.to_s)
        }
      else
        format.html { render :action => 'new' }
      end
    end
  end

  def destroy
    @project = Project.find(params[:project_id])
    @comment = Comment.find(params[:id])
    authorize! :destroy, @comment
      
    # destroy public activities associated with comment
    if @comment.activities
      @comment.activities.destroy_all
    end

    @comment.destroy

    respond_to do |format|
      format.html {redirect_to project_steps_path(@project)}
    end
  end

  end