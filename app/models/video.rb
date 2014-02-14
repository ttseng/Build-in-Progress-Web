require 'httparty'

class Video < ActiveRecord::Base
  # maybe we should add a title attribute to the video?
  attr_accessible :position, :project_id, :step_id, :image_id, :saved, :embed_url, :thumbnail_url, :video_path, :user_id
  mount_uploader :video_path, VideoPathUploader

  # position videos before images...
  # show video thumbnails, make them sortable.

  # maybe video and images should be based around a polymorphic
  # association with steps and projects.
  # or maybe they should just belong to steps, and be related
  # to projects with has_many :videos, :through => :steps

  belongs_to :step
  belongs_to :project
  belongs_to :user, :touch=>true
  belongs_to :image

  validate :url_is_from_approved_site?, if: :embedded?

  def url_is_from_approved_site?
    approved_sites = ["youtube", "vimeo"]
    valid = false
    approved_sites.each do |site|
      if embed_url.downcase.include?(site)
        valid = true
      end
    end
    return valid
  end

  # checks if the video is embedded
  def embedded?
    return embed_url && !embed_url.empty?
  end

  # returns the embed code of a video from the embed_url
  # '<iframe src="http://www.youtube.com/embed/mZqGqE0D0n4" frameborder="0" allowfullscreen="allowfullscreen"></iframe>'"
  def embed_code
    if url_is_from_approved_site?
      return VideoInfo.get(embed_url).embed_code
    else
      return false
    end
  end

  def youtube?
    !embed_url.nil? and embed_url.include?("youtube")
  end

  def vimeo?
    !embed_url.nil? and embed_url.include?("vimeo")
  end

  def vid_id
      vid_id = VideoInfo.get(embed_url).video_id
    return vid_id
  end

  # get thumbnail url for preview image of video
  def thumb_url
    # first see if we have a cached thumbnail
    if thumbnail_url
      return thumbnail_url
    else
      thumbnail_url = VideoInfo.get(embed_url).thumbnail_large
    end
      
    # save the new thumbnail
    if thumbnail_url
       save
    end

    return thumbnail_url
  end

  # script for adding user id to video after migration
  def add_user
    user_id = step.users.first.id
    update_attributes(:user_id => user_id)
  end

end