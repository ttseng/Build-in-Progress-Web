class Project < ActiveRecord::Base
  include PublicActivity::Common
  acts_as_api

  has_ancestry :orphan_strategy => :adopt, :ancestry_column => :remix_ancestry

  attr_accessible :title, :images_attributes, :design_files_attributes, :user_id, :built, :remix, :published, :featured, :featured_on_date, :updated_at, :remix_ancestry, :description
  has_many :steps, :dependent => :destroy
  has_many :images, :dependent => :destroy
  has_many :videos, :dependent => :destroy
  has_many :sounds, :dependent => :destroy
  has_many :edits, :dependent => :destroy
  has_many :design_files, :dependent => :destroy

  has_and_belongs_to_many :users

   # Favorited by users
  has_many :favorite_projects, :dependent=> :destroy
  has_many :favorited_by, :through => :favorite_projects, :source => :user # users that favorite a project

  has_many :collectifies, :dependent => :destroy
  has_many :categorizations, :dependent => :destroy
  has_many :collections, :through => :collectifies
  has_many :categories, :through => :categorizations

  accepts_nested_attributes_for :steps
  accepts_nested_attributes_for :images
  accepts_nested_attributes_for :videos
  accepts_nested_attributes_for :design_files

  validates :title, :presence => true, length: {maximum: 40}
  scope :built, where(:built => true)
  scope :not_built, where(:built=> false)
  scope :published, where(:published=>true)
  scope :unpublished, where(:published => false)
  scope :featured, where(:featured=>true)

  # define whether a project is published
  def published?
    published = false
    if is_remix?
      # check if the remix has been updated (user has either added new step or added new image, edited a step)
      if (updated_at != created_at) && (images.count>0)
        published = true
      end
    else
      # for non remixed projects, projects are published if the title has been updated and a picture has been uploaded
      if !title.starts_with?("Untitled")
        if images.count > 0
          published = true
        end
      end
    end
    return published
  end

  # for generating json file of user projects
  def image_path
    images = Hash.new
    unless last_step_with_images.blank?
      if !last_step_with_images.first_image.is_remix_image?
        images["url"] = last_step_with_images.first_image.image_path_url    
        images["preview"] = last_step_with_images.first_image.image_path_url(:preview) 
        images["thumb"] = last_step_with_images.first_image.image_path_url(:thumb) 
      else
        images["url"] = last_step_with_images.first_image.original_image.image_path_url    
        images["preview"] = last_step_with_images.first_image.original_image.image_path_url(:preview) 
        images["thumb"] = last_step_with_images.first_image.original_image.image_path_url(:thumb) 
      end
    end

    return images
  end

  def default_image
    step_of_last_image = last_step_with_images
    unless step_of_last_image.blank?
      if !step_of_last_image.first_image.is_remix_image?
        step_of_last_image.first_image
      elsif !step_of_last_image.first_image.blank?
        step_of_last_image.first_image.original_image
      end
    end
  end

  def homepage_image
    steps.order("position DESC").each do |step|
      step.images.order("position ASC").each do |image|
        if image.video == nil && image.sound == nil
          if !image.is_remix_image?
            return image
          else
            return  Image.find(image.original_id)
          end
        end
      end
    end
  end

  def is_remix?
    return !remix_ancestry.blank?
  end

  def remix?
    return is_remix?
  end

  def remix_image_preview
    Image.find(first_step.first_image.original_id).image_path_url(:preview)
  end

  def built_step
    steps.where(:last=>true).last()
  end

  def first_step
    steps.order(:position).first
  end

  def overview
    self.first_step
  end

  def non_first_steps
    steps.where("position != 0").order(:published_on)
  end

  def updated_at_formatted
     updated_at.strftime("%m/%d/%Y %H:%M:%S")
  end

  def remix_count
    descendants.published.count
  end

  def comment_count
    counter = 0
    steps.each do |step|
      counter = counter+step.comment_threads.length
    end
    return counter
  end

  # determine the last step of a project that contains an image
  def last_step_with_images
    last_step = ""
    steps.order("published_on DESC").each do |step|
      if step.images.count>0
        last_step = step
        return last_step
      end
    end
    return last_step
  end

  def remix(current_user)
    # remix_project = @project.dup :include => [{:steps=> [:videos, :images]}]
    remix_project = dup :include => [:steps], :except => :published

    remix_project.parent_id = id
    remix_project.users << current_user

    remix_project.built = false

    # add remix to the title if it doesn't already include remix and the title won't exceed maximum number of characters
    if (!(title.include? "Remix") && title.length < 24 )
      remix_project.title = title+" Remix"
    end

    if remix_project.save        
      # remove any existing project description
      remix_project.update_attributes(:description=>"")

      original_project_steps = steps.order(:position)
      remix_project_steps = remix_project.steps.order(:position)

      # # FIRST: remap ancestry of new steps
      # # map new steps with old steps 
      step_hash = Hash.new # format: {original_step.id: remix_project_step.id}
      original_project_steps.each_with_index do |step, index|
        step_hash[original_project_steps[index].id]=remix_project_steps[index].id
      end

      # Rails.logger.debug "step_hash #{step_hash.inspect}"

      # replace ancestry of new remix project steps with new ids
      remix_project_steps.each do |remix_step|
        remix_ancestry_array = Array.new
        original_step_ancestry = original_project_steps.where(:position=> remix_step.position).first.ancestry
        # Rails.logger.debug("original step ancestry #{original_step_ancestry}")
        if original_step_ancestry.match("/") != nil
          original_ancestry_array = original_step_ancestry.split("/") 
        else
          original_ancestry_array = [original_step_ancestry]
        end
        
        # define remix_ancestry_array
        (0..original_ancestry_array.length-1).each do |i|
          remix_ancestry_array.push(step_hash[Integer(original_ancestry_array[i])])
        end
        # Rails.logger.debug("remix_ancestry_array: #{remix_ancestry_array}")
        # turn remix_ancestry_array array to string
        remix_ancestry = remix_ancestry_array.join('/')
        # Rails.logger.debug("remix ancestry for #{remix_step.id}: #{remix_ancestry}")
        if remix_ancestry != nil
            remix_step.update_attributes(:ancestry=> remix_ancestry)
        end

        # set original authors for the remix step
        author_array = Array.new
        original_project_steps.where(:position => remix_step.position).first.users.order("username").each do |user|
          remix_step.users << user
          author_array.push(user.id)
        end

        if remix_step.ancestry.blank?
          remix_step.update_attributes(:original_authors => author_array, :ancestry=>0) 
        else
          remix_step.update_attributes(:original_authors => author_array) 
        end

        if !
          Rails.logger.debug("#{remix_step.errors.inspect}")
        end

        if remix_step.last
          remix_step.update_attributes(:last=>false)
        end

      end

      images.each do |image|
        remix_image = image.dup 
        remix_image.step_id=step_hash[image.step_id]

        if remix_image.is_remix_image?
          # if we're making a remix of a remix, reference the original id
          remix_image.original_id=image.original_id
        else
          # if we're making a remix of a non-remixed image, reference the original image's id
          remix_image.original_id = image.id
        end

        remix_image.save
        Rails.logger.debug("created image #{remix_image.id}")
        remix_project.images << remix_image
        
        if image.video
          remix_video = image.video.dup 
          remix_video.step_id = step_hash[image.step_id]
          remix_project.videos << remix_video
        end
      end

    end
    return remix_project
  end

  # feature the project
  def feature
    self.record_timestamps = false
    self.update_attributes(:featured=>true)
    self.update_attributes(:featured_on_date=>DateTime.now)
    self.record_timestamps = true
    self.users.each do |user|
      self.create_activity :feature, recipient: user, primary: true
      self.create_activity :feature_public, owner: user, primary: true
    end
    
  end

  def unfeature
    self.record_timestamps = false
    self.update_attributes(:featured=>false)
    self.record_timestamps = true
    PublicActivity::Activity.where("key = ? AND trackable_id = ?", "project.feature", self.id).destroy_all
    PublicActivity::Activity.where("key = ? AND trackable_id = ?", "project.feature_public", self.id).destroy_all
  end

  def has_unanswered_question?
    steps.each do |step|
      if step.question && step.question.answered == false
        return true
      end
    end
    return false
  end

  def step_with_question
    question_step = ""
    steps.order(:published_on).each do |step|
      if step.question && step.question.answered == false
        question_step = step
      end
    end
    return question_step
  end

  # images only associated with images (not video or sounds)
  def photo_images_count
    images.where(:video_id=>nil).where(:sound_id=>nil).count
  end

  def collaborative?
    return users.count > 1
  end

  def set_built
    if steps.pluck(:last).include? true
      update_attributes(:built => true)
    else
      update_attributes(:built => false)
    end
  end


  ### SCRIPTS ###

  # script for multi-author projects (1/10/2014)
  def multi_author_project_script
    # add project users
    Project.all.each do |project|
      project.add_project_users
    end

    # create edits
    Step.all.each do |step|
      step.add_edits
    end

    # add user_ids to images and video
    Image.all.each do |image|
      image.add_user
    end

    Video.all.each do |video|
      video.add_user
    end

    # add original authors
    Project.where("remix_ancestry IS NOT NULL").each do |project|
      project.steps.each do |step|
        step.set_original_authors
      end
    end

  end

  # script for adding a project description to a project based on the overview description 
  def add_project_description
      clean_overview = ActionView::Base.full_sanitizer.sanitize(overview.description)
      clean_overview = clean_overview.gsub("&nbsp", "")
      clean_overview = clean_overview.gsub("&#39;", "'")
      clean_overview = clean_overview.gsub("\r\n", " ")
      clean_overview = clean_overview.gsub("&quot;", '"')
      clean_overview = clean_overview.gsub(";", ' ')
      update_attributes(:description=> clean_overview)
  end

  # add users to projects after creating projects_users table
  def add_project_users
    project_user = User.find(user_id)
    users << project_user
  end

  # script for updating position of steps based on published on date
  def reset_step_positions
    steps.order(:published_on).each_with_index do |step, index|
      step.update_attributes(:position=>index)
    end
  end

  # reset_ancestry: script for resetting the ancestry of steps in a project into a single, linear chain
  def reset_ancestry
    steps.order(:position).each do |step|
      step.update_attributes(:ancestry=>steps.order(:position)[step.position-1].id)
    end
  end

end