class News < ActiveRecord::Base
  attr_accessible :description, :step_id, :title, :news_type, :created_at
  validates :title, :presence => true, length: {maximum: 60}

  # Script to generate news from existing mobile + desktop bip projects
  def generate_news
  	website_project = Project.where(:title=>"Build in Progress Website").where(:remix_ancestry => nil).first()
  	if website_project
  		website_project.steps.order("created_at ASC").each do |step|
  			news_step_id = step.id
  			news_title = step.name
  			news_type = "website"
  			News.create(:title => news_title, :step_id => news_step_id, :news_type => news_type, :created_at => step.created_at)
  		end
    end

    mobile_project = Project.where(:title=>"Build in Progress Mobile").where(:remix_ancestry => nil).first()
    if mobile_project
    	mobile_project.steps.order("created_at ASC").each do |step|
    		news_step_id = step.id
  			news_title = step.name
  			news_type = "mobile"
			News.create(:title => news_title, :step_id => news_step_id, :news_type => news_type, :created_at => step.created_at)
    	end
    end

  end
end
