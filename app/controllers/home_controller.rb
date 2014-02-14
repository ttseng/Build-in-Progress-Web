class HomeController < ApplicationController
  def index
  	if current_user
  		@activities = PublicActivity::Activity.order("created_at desc").where(owner_id: current_user.following_users, owner_type: "User").where("created_at > ? ", 2.weeks.ago).limit(10)
  	end
  	@latestProjects = Project.published.order("updated_at DESC").limit(5)
  	@featuredProjects = Project.featured.order("featured_on_date DESC").limit(4)

    website_project = Project.where(:title=>"Build in Progress Website").where(:remix_ancestry => nil).first()
    mobile_project = Project.where(:title=>"Build in Progress Mobile").where(:remix_ancestry => nil).first()
    if website_project && mobile_project
    	 website_project_latest = website_project.steps.where("position !=?", 0).order("published_on DESC").first()
    	 mobile_project_latest = mobile_project.steps.where("position !=?", 0).order("published_on DESC").first()

    	if website_project_latest && mobile_project_latest
        if website_project_latest.published_on > mobile_project_latest.published_on
      		if website_project_latest.published_on > 1.week.ago
      			@latestNews = website_project_latest
      		end
      	else
      		if mobile_project_latest.published_on > 1.week.ago
      			@latestNews = mobile_project_latest
      		end
      	end
      end
    end 
  end

  def hide_announcement
  	cookies.permanent.signed[:hidden_announcement_id] = params[:id]
  	respond_to do |format|
  		format.html {redirect_to :back}
  		format.js
  	end
  end

end
