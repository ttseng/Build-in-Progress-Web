PublicActivity::Activity.class_eval do
	attr_accessible :created_at, :primary, :viewed
	after_initialize :init

	# script for generating primary attribute for existing comments
	def update_primary
		PublicActivity::Activity.all.each do |activity|
			if activity.trackable_type == "Comment"
				if activity.trackable.commentable.user != activity.recipient
					activity.update_attributes(:primary=>false)
				else
					activity.update_attributes(:primary=>true)
				end
			else
				activity.update_attributes(:primary=>true)
			end
		end
	end

	# script for updating the notification viewed boolean 
	def update_viewed
		PublicActivity::Activity.all.each do |activity|
			if activity.recipient && activity.recipient.notifications_viewed_at > activity.created_at
				activity.update_attributes(:viewed=>true)
			else
				activity.update_attributes(:viewed=>false)
			end
		end
	end

	# called after public activity is created
	def init
		# set the viewed to false by default
		self.viewed = false if self.viewed.nil?
	end

	# returns true if it's a followed comment
	def is_followed_comment?
		return !primary
	end

	def self.comments
		where(:trackable_type=>"Comment")
	end

	def self.favorited_projects
		where(:trackable_type=>"FavoriteProject")
	end

	def self.project
		where(:trackable_type=>"Project")
	end
end