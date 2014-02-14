require 'httparty'
require 'soundcloud'

class Sound < ActiveRecord::Base
  attr_accessible :project_id, :step_id, :image_id, :saved, :embed_url, :thumbnail_url, :user_id

  belongs_to :step
  belongs_to :project
  belongs_to :user, :touch=>true
  belongs_to :image

  # returns the embed code of a soundcloud from the embed_url
  def embed_code
    response = HTTParty.get(embed_url)
  end

  # returns the ID of the soundcloud
  def soundcloud_id
  end

  # returns the thumbnail url for the soundcloud file
  def thumb_url
  end

  # add user_id to sounds after migration
  def add_user
    user_id = step.users.first.id
    update_attributes(:user_id => user_id)
  end

end
