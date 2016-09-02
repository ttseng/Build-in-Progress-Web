class ActivityFeedController < ApplicationController
	before_filter :authenticate_user!

  def index
	@activities = current_user.followers_activity.where("created_at > ? ", 2.weeks.ago).public_activities.uniq_by(&:trackable_id)
  end

end
