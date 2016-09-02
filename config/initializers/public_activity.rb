PublicActivity::Activity.class_eval do
	attr_accessible :created_at, :primary, :viewed
	before_create :init

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

	# cover activities from projects that are private or unlisted
	def is_private?
		( (key == "project.feature_public" && trackable.present? && trackable.private?) ||
          (trackable_type == "Step" && trackable.present? && trackable.project.private?) ||
		  (trackable_type == "Project" && trackable.present? && trackable.private?) ||
		  (trackable_type == "Collectify" && trackable.present? && trackable.project.private?) 
		 )
	end

	def self.public_activities
		PublicActivity::Activity.all.select{ |a| !a.is_private?}
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

	def is_comment?
		key == "comment.create"
	end

	def is_featured?
		key=="project.feature"
	end

	def is_added_as_collaborator?
		key=="project.author_add"
	end

	def is_favorited?
		key=="favorite_project.create"
	end

	def is_added_to_collection?
		key=="collectify.create"
	end

	def is_updated_collection?
		key=="collectify.owner_create"
	end

	def is_followed?
		key=="user.follow"
	end

	def is_remixed?
		key=="project.create" && trackable.root
	end
end