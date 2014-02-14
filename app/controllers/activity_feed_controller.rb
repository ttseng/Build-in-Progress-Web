class ActivityFeedController < ApplicationController
	before_filter :authenticate_user!

  def index
	@activities = PublicActivity::Activity.order("created_at desc").where(owner_id: current_user.following_users, owner_type: "User").where("created_at > ?", 2.weeks.ago)
  end

end
