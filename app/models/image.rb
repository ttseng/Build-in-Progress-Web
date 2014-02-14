class Image < ActiveRecord::Base

  attr_accessible :project_id, :step_id, :image_path, :caption, :position, :saved, :remote_image_path_url, :video_id, :original_id, :sound_id, :user_id, :s3_filepath

  belongs_to :step
  belongs_to :project, :touch => true
  belongs_to :user, :touch=> true

  has_one :video, :dependent => :destroy
  has_one :sound, :dependent => :destroy

  belongs_to :original_image, :class_name=>"Image", :foreign_key => "original_id"
  has_many :remix_images, :class_name=>"Image", :foreign_key=> "original_id", :dependent => :destroy

  mount_uploader :image_path, ImagePathUploader

  before_create :default_name

  # validates :image_path, :presence => true

  def default_name
    self.image_path ||= File.basename(image_path.filename, '.*').titleize if image_path
  end

  def has_video?
    return !video.blank?
  end

  def has_sound?
    return !sound.blank?
  end

  def is_remix_image?
    return !original_id.blank?
  end

  def author
    Image.find(original_id).user.username
  end

  # script to add user id to each image after running migration
  def add_user
    image_user_id = step.users.first.id
    update_attributes(:user_id => image_user_id)
  end

  # used for pointing to remix images in project/index.json.erb file - must be titled
  # image_path to render correctly
  def remix_image_path
    remix_image_paths = Hash.new
    if original_id
      remix_image_paths["url"] = Image.find(original_id).image_path_url
      remix_image_paths["preview"] = {:url => Image.find(original_id).image_path_url(:preview)}
      remix_image_paths["thumb"] = {:url => Image.find(original_id).image_path_url(:thumb)}
      remix_image_paths["square_thumb"] = {:url => Image.find(original_id).image_path_url(:square_thumb)}
    else
      remix_image_paths["url"] = image_path_url
      remix_image_paths["preview"] = {:url => image_path_url(:preview)}
      remix_image_paths["thumb"] = {:url => image_path_url(:thumb)}
      remix_image_paths["square_thumb"] = {:url => image_path_url(:square_thumb)}
    end
    return remix_image_paths
  end

  def remix_video_path
    video_hash = Hash.new
    if video_id
      if video == nil
        logger.debug("VIDEO ID : #{video_id}")
        # get remix video
        original_video = Video.find(video_id)
        if original_video.embedded?
          video_hash['embed_url'] = original_video.embed_url
        else
          video_hash['embed_url'] = ""
          video_paths = Hash.new
          video_paths['url'] = original_video.video_path_url
          video_paths['webm'] = {:url => original_video.video_path_url(:webm)}
          video_hash['video_path'] = video_paths
        end
      else
        # get new video added to remix project
        if video.embedded?
          video_hash['embed_url'] = video.embed_url
        else
          video_paths = Hash.new
          video_paths['url'] = video.video_path_url
          video_paths['webm'] = {:url => video.video_path_url(:webm)}
          video_hash['video_path'] = video_paths
        end
      end
      return video_hash
    end
  end

end