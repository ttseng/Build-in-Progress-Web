class Project < ActiveRecord::Base
  include PublicActivity::Common
  include ActionView::Helpers::SanitizeHelper
  require 'rubygems'
  require 'zip'
  require 'htmlentities'

  acts_as_api

  has_ancestry :orphan_strategy => :adopt, :ancestry_column => :remix_ancestry

  attr_accessible :title, :images_attributes, :design_files_attributes, :user_id, :built, :remix, :featured, :featured_on_date, :updated_at, :remix_ancestry, :description, 
                  :village_id, :privacy, :cover_image
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
  scope :featured, where(:featured=>true)
  scope :remixes, where("remix_ancestry IS NOT NULL")
  scope :private_projects, where(:privacy => "private")
  scope :unlisted_projects, where(:privacy => "unlisted")
  scope :public_projects, where(:privacy => "public")

  searchable do
    text :description, :stored => true do
      strip_tags(description)
    end
  end

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

  # sets published for project
  def set_published(current_user_id, project_id, step_id)
    project = Project.find(project_id)
    
    if step_id != nil
      step = Step.find(step_id)
    end
    current_user = User.find(current_user_id)

    if project.published? and project.privacy.blank?
      # project went from being unlisted to published
      if project.is_remix?
        # create a notification for the remix project
        project.ancestors.each do |ancestor|
          ancestor.users.each do |user|
            if user != current_user
              @activity = project.create_activity :create, owner: current_user, recipient: user, primary: true
              # create an email notification for newly remixed project
              if user.settings(:email).remixed == true
                NotificationMailer.delay.notification_message(@activity, user)
              end
            end
          end
        end
      else
        # create notification for new project
        project.create_activity :new, owner: current_user, primary: true
      end
      project.update_attributes(:privacy => "public")
    elsif project.published? && !project.private?
      # create activities for creating / updating steps
      if project.is_remix?
        # create activities to remix ancestors that the project has been remixed
        project.ancestors.each do |ancestor|
          ancestor.users.each do |user|
            if user != current_user && step_id != nil
              if (step.created_at - step.updated_at).abs.to_i > 1
                # step was updated
                step.create_activity :update, owner: current_user, recipient: user, primary: true
              else
                # new step was created
                step.create_activity :create, owner: current_user, recipient: user, primary: true
              end
            end
          end
        end
      elsif step_id != nil
        # create activity for updated / creating steps (non-remixes)
        if (step.created_at - step.updated_at).abs.to_i > 1
          # step was updated
          step.create_activity :update, owner: current_user, primary: true
        else
          # step was created
          step.create_activity :create, owner: current_user, primary: true
        end
      end
      # project is published
      project.update_attributes(:privacy => "public")

    elsif !project.published?
      # project has become unpublished - delete all activities about it
      PublicActivity::Activity.where(:trackable_id => project.id).destroy_all
      project.steps.each do |step|
        PublicActivity::Activity.where(:trackable_id => step.id).destroy_all
      end
      if project.featured
        project.update_attributes(:featured => false)
      end
      project.update_attributes(:privacy => nil)
    end
  end

  def unlisted?
    self.privacy == "unlisted"
  end

  def public?
    self.privacy == "public"
  end

  def private?
    self.privacy == "private"
  end

  def unpublished?
    self.privacy.blank?
  end

  # for generating json file of user projects
  def image_path
    images = Hash.new
    step = last_step_with_images
    if !step.blank? && !step.last_image.is_remix_image?
        last_image = step.last_image
        images["url"] = last_image.image_path_url    
        images["preview"] = last_image.image_path_url(:preview) 
        images["thumb"] = last_image.image_path_url(:thumb) 
    elsif !step.blank?
        # load remix images
        last_image = step.last_image.original_image
        images["url"] = last_image.image_path_url    
        images["preview"] = last_image.image_path_url(:preview) 
        images["thumb"] = last_image.image_path_url(:thumb) 
    end
    return images
  end

  # default_image: for non-remix projects- fetches the last image of the most recently published step in a project
  #                for remixed projects show the latest uploaded image
  def default_image
    if !self.is_remix?
       # find the last image of the project
       image = Image.unscoped.where(:project_id => id).where("image_path IS NOT NULL").joins(:step).order('steps.published_on DESC').order('position DESC').first
       unless image.blank?
         return image
        end
    elsif Image.where(:project_id => id).length > 0
      if Image.unscoped.where(:project_id => id).where("image_path IS NOT NULL").where("original_id IS NULL").present?
        return Image.unscoped.where(:project_id => id).where("image_path IS NOT NULL").where("original_id IS NULL").joins(:step).order('steps.published_on DESC').order('position DESC').first
      else
        image = Image.unscoped.where(:project_id => id).where("image_path IS NOT NULL").joins(:step).order('steps.published_on DESC').order('position DESC').first
        if !image.original_id || image.blank?
          return image
        else
          return Image.find(image.original_id)
        end
      end
    else
      return nil
    end
  end

  # last_step_with_images: fetches the last step that has images in a project
  def last_step_with_images
    unless default_image.blank?
      return default_image.step
    end
  end

  # last_step_with_images_no_vid
  def last_step_with_images_no_vid
    unless homepage_image.blank?
      if !is_remix?
        return homepage_image.step
      else
        steps.joins(:images).order('steps.published_on DESC').first
      end
    end
  end
  
  # homepage_image: returns the last image from a project (excludes thumbnail images made from videos or sound files)
  def homepage_image
    if cover_image.present? && Image.find(self.cover_image)
      homepage_image = Image.find(self.cover_image)
      if homepage_image.original_id.blank?
        return homepage_image
      else
        return Image.find(homepage_image.original_id)
      end
    else
      homepage_image = Image.unscoped.where(:project_id => id).images_only.where("image_path IS NOT NULL").joins(:step).order('steps.published_on DESC').order('position DESC').first
      unless homepage_image.blank?
        if homepage_image.original_id.blank?
          return homepage_image
        else
          return Image.find(homepage_image.original_id)
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
    Image.find(first_step.last_image.original_id).image_path_url(:preview)
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
    descendants.public_projects.count
  end

  def steps_count
    steps.count
  end

  def word_count
    words = 0
    self.steps.each do |step|
      words = words + step.description.length if step.description
    end
    return words
  end

  def image_count
    self.images.count
  end

  def comment_count
    step_ids = Project.includes(:steps).find(self.id).steps.pluck(:id)
    counter = 0
    Step.includes(:comment_threads).where(:id => step_ids).each do |step|
       counter = counter+step.comment_threads.length 
     end
    return counter
  end

  def remix(current_user)

    # remix_project = @project.dup :include => [{:steps=> [:videos, :images]}]
    remix_project = dup :include => [:steps], :except => :privacy

    remix_project.parent_id = id
    remix_project.users << current_user

    remix_project.built = false
    remix_project.featured = nil
    remix_village_id = nil # remove relationship to village
    remix_project.created_at = Time.now
    remix_project.updated_at = Time.now

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
        if original_step_ancestry && original_step_ancestry.match("/") != nil
          original_ancestry_array = original_step_ancestry.split("/") 
        elsif !original_step_ancestry
          original_ancestry_array = [0]
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
    Project.record_timestamps = false
    self.update_attributes(:featured=>true)
    self.update_attributes(:featured_on_date=>DateTime.now)
    self.users.each do |user|
      @activity = self.create_activity :feature, recipient: user, primary: true
      self.create_activity :feature_public, owner: user, primary: true
      # create email notification 
      if user.settings(:email).featured == true
        puts "creating notification email for user #{user.username}"
        NotificationMailer.delay.notification_message(@activity, user)
      end
    end
    Project.record_timestamps = true
  end

  def unfeature
    Project.record_timestamps = false
    self.update_attributes(:featured=>false)
    Project.record_timestamps = true
    PublicActivity::Activity.where("key = ? AND trackable_id = ?", "project.feature", self.id).destroy_all
    PublicActivity::Activity.where("key = ? AND trackable_id = ?", "project.feature_public", self.id).destroy_all
  end

  # returns the id of the last instance of a step with an unanswered question
  def step_with_question
    question_step = ""
    if Project.joins(steps: :question).pluck(:id).include? self.id
      step = Step.joins(:question).where(:project_id => self.id).order("updated_at").last
      if !step.question.answered?
        question_step = step.id
      end
    end
    return question_step

    # steps.order(:published_on).each do |step|
    #   if step.question && step.question.answered == false
    #     question_step = step.id
    #   end
    # end
    # return question_step
  end

  def questions
    project_questions = Array.new
    steps.order(:published_on).each do |step|
      if step.question 
        project_questions << step.question
      end
    end
    return project_questions
  end

  # images only associated with images (not video or sounds)
  def photo_images_count
    images.where(:video_id=>nil).count
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

  # return an array of ids of project authors that are registered on the village
  def village_user_ids
    users.collect do |user|
      user.uid
    end.compact
  end

  # export_txt - returnings all the descriptions in a project (project description + step descriptions) into a single
  # txt file
  def export_txt
    if !File.directory?("#{Rails.root}/tmp/txt/") 
      Dir.mkdir(Rails.root.join('tmp/txt'))
    end

     txt_directory = "#{Rails.root}/tmp/txt/#{self.id}.txt"
     txt = ""

     txt = txt + (HTMLEntities.new.decode ActionView::Base.full_sanitizer.sanitize(self.description)) + "\n \n"

      self.steps.not_labels.order("published_on").each do |step|
        if step.description.present?
          # add step description
          txt = txt + (HTMLEntities.new.decode ActionView::Base.full_sanitizer.sanitize(step.description)) + "\n \n"
        end
      end
      File.open(txt_directory, 'w') do |f|
        f.puts txt
      end
  end


  # export - returns a zip file of all the contentsn of a project, with a subdirectory for each step containing the
  # step description + any images or videos and design files
  def export
    if !File.directory?("#{Rails.root}/tmp/zips/") 
      Dir.mkdir(Rails.root.join('tmp/zips'))
    end

    archive_file = "#{Rails.root}/tmp/zips/#{self.id}-#{self.title.delete(' ')}.zip"
   
    Zip::OutputStream.open(archive_file) do |zipfile|
      # add project description
      zipfile.put_next_entry("project_description.txt")
      zipfile.print(self.description)

      step_num = 0
      step_increment = false

      self.steps.not_labels.order("published_on").each do |step|
        logger.debug("on step #{step.name} with step_num #{step_num}")
        if step.description.present?
          # add step description
          zipfile.put_next_entry(step_num.to_s + " - " + step.name + "/description.txt")
          step_increment = true
          zipfile.print(HTMLEntities.new.decode ActionView::Base.full_sanitizer.sanitize(step.description))
        end

        # add media
        step.images.each do |image|
          if image.is_remix_image?
            image = Image.find(image.original_id)
          end

          if !image.has_video?
            # add images
            if image.image_path.present?
              # add uploaded image
              img_path = image.image_path_url
              step_increment = true
            elsif image.s3_filepath.present?
              # add direct upload image
              img_path = image.s3_filepath
              step_increment = true
            else
              img_path = nil
            end

            if img_path != nil
              filename = File.basename(URI.parse(img_path).path)
              logger.debug("image filename: #{filename}")
              zipfile.put_next_entry(step_num.to_s + " - " + step.name + "/" + filename)
              zipfile.print(URI.parse(img_path).read)
            end
          
          elsif !image.video.embedded?
            # add no embedded video
             filename = File.basename(URI.parse(image.video.video_path_url).path)
             logger.debug("video filename: #{filename}")
             zipfile.put_next_entry(step_num.to_s + " - " + step.name + "/" + filename)
             begin
                zipfile.print(URI.parse(image.video.video_path_url).read)
                step_increment = true
             rescue OpenURI::HTTPError
                # don't export videos with these errors
             end
          end
        end # end step.images.each do |image|

        step.design_files.each do |design_file|
          filename = File.basename(URI.parse(design_file.design_file_path_url).path)
          zipfile.put_next_entry(step_num.to_s + " - " + step.name + "/" + filename)
          zipfile.print(URI.parse(design_file.design_file_path_url).read)
          step_increment = true
        end

        if step_increment
          step_increment = false
          step_num = step_num+1
        end
        
      end
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

  # tree_width - finds the total number of branches in a project
  def tree_width
    num_branches = 0
    ancestry = self.steps.pluck(:ancestry)
    repeat_ancestry = ancestry.group_by {|e| e}.select { |k,v| v.size > 1}.keys
    repeat_ancestry.each do |value|
      num_branches = num_branches + ancestry.grep(value).size
    end
    return num_branches
  end

  # num_branches
  # finds the number of branches a project has
  # returns the number of branches
  def num_branches
    num_branches = 0
    ancestry = self.steps.pluck(:ancestry)
    repeat_ancestry = ancestry.group_by {|e| e}.select { |k,v| v.size > 1}.keys
    repeat_ancestry.each do |value|
      num_branches = num_branches + ancestry.grep(value).size
    end
    return num_branches
  end

  # log: create a log file of project updates on aws
  def log
    project_id = self.id
    if Project.exists?(project_id)
      @project = Project.find(project_id)
      s3 = AWS::S3.new(:access_key_id => ENV['AWS_ACCESS_KEY_ID'], :secret_access_key => ENV['AWS_ACCESS_KEY'])
        key = "logs/" + project_id.to_s + ".json"
        project_json = []

        obj = s3.buckets[ENV['AWS_BUCKET']].objects[key]
        if obj.exists?
            # get the current log file if it exists and append to it
            puts "fetching existing json file"
            project_json = JSON.parse(obj.read)
        end
    
        # only create log for new projects (not existing projects)
        if !obj.exists?
          # store all steps in the log file
          steps_json = []
          @project.steps.order(:position).each do |step|
            #step.as_json(:only => [:id, :name, :position, :ancestry, :label, :label_color], :method => :first_image_path)
            step_json = {
              "id" => step.id,
              "name" => step.name,
              "position" => step.position,
              "ancestry" => step.ancestry
            }
            # step_json["thumbnail_id"] = step.first_image.id if step.first_image.present?
            step_json['label'] = step.label if step.label.present?
            step_json['label_color'] = step.label_color if step.label.present?

            steps_json << step_json
          end

          # create new json file
          project_json = {
            "data" => [
              "updated_at" => @project.updated_at.to_s, 
              "title" => @project.title,
              "word_count" => @project.word_count,
              "image_count" => @project.image_count,
              "steps" => steps_json
            ]
          }      
          puts '===========ADDING LOG==========='
          s3.buckets[ENV['AWS_BUCKET']].objects[key].write(project_json.to_json)
        else
               # store all steps in the log file
          steps_json = []
          @project.steps.order(:position).each do |step|
            #step.as_json(:only => [:id, :name, :position, :ancestry, :label, :label_color], :method => :first_image_path)
            step_json = {
              "id" => step.id,
              "name" => step.name,
              "position" => step.position,
              "ancestry" => step.ancestry
            }
            # step_json["thumbnail_id"] = step.first_image.id if step.first_image.present?
            step_json['label'] = step.label if step.label.present?
            step_json['label_color'] = step.label_color if step.label.present?

            steps_json << step_json
          end
          
          # append project update to existing json
          update_json = {
            "updated_at" => @project.updated_at.to_s,
            "title" => @project.title,
            "word_count" => @project.word_count,
            "image_count" => @project.image_count,
            "steps" => steps_json
          }

          # puts "update_json #{update_json}"

          project_json = {
            "data" => project_json["data"] << update_json
          }

          # puts "project_json.to_json #{project_json.to_json}"
          puts '===========ADDING LOG==========='
          s3.buckets[ENV['AWS_BUCKET']].objects[key].write(project_json.to_json)
        end
      end
  end 

  # thumbnail_images - returns an array containing the urls of thumbnail images given the corresponding step_ids
  def thumbnail_images(step_ids_array)
    thumbnail_images = []
    step_ids_array.each do |id|
      if Step.exists?(id)
        step_first_image = Step.find(id).first_image
        if step_first_image.present? && step_first_image.original_image.blank?
          thumbnail_images << step_first_image.image_path_url(:square_thumb) || step_first_image.s3_filepath 
        elsif step_first_image.present? && step_first_image.original_image.present?
          thumbnail_images << Image.find(step_first_image.original_image).image_path_url
        else
          thumbnail_images << nil
        end
      else
        thumbnail_images << nil
      end
    end
    return thumbnail_images
  end

  # broken? - check if the positions in a project are not consequetive
  def broken?
    if self.steps.length == 0
      return false
    else
      step_positions = self.steps.order(:position).pluck(:position)
      if step_positions.length > 1
        expected_positions = (0..step_positions.length-1).to_a  
      else
        expected_positions = [0]
      end
      return (expected_positions != step_positions) || self.steps.where(:position => 0).length>1
    end
  end


  # SCRIPTS
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

  # add privacy attribute to existing projects - published projects are public, unpublished are unlisted
  def add_privacy
    if self.published?
      self.update_attributes(:privacy => "public")
    end
  end

end