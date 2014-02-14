class FavoriteProject < ActiveRecord::Base
	include PublicActivity::Common
  	attr_accessible :project_id, :user_id
  	belongs_to :project
  	belongs_to :user
end
