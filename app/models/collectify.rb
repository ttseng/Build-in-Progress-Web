class Collectify < ActiveRecord::Base
  include PublicActivity::Common
  belongs_to :project
  belongs_to :collection
  
  attr_accessible :collection_id, :project_id
end
