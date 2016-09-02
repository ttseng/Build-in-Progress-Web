class Step < ActiveRecord::Base
  include PublicActivity::Common
  include ActionView::Helpers::SanitizeHelper
	extend FriendlyId

  serialize :original_authors

	acts_as_commentable
  	friendly_id :position

  	has_ancestry :orphan_strategy => :adopt

  	attr_accessible :description, :name, :position, :project_id, :images_attributes, :parent_id, :ancestry, :published_on, :last, :user_id, :question_attributes, :design_files_attributes, :original_authors, :label, :label_color, :pin

  	belongs_to :project
    
    has_many :users, through: :edits
    has_many :edits, :dependent => :destroy
    
  	has_many :images, :dependent => :destroy
    has_many :videos, :dependent => :destroy
    has_many :sounds, :dependent => :destroy
    has_one :question, :dependent => :destroy
    has_many :design_files, :dependent => :destroy

    accepts_nested_attributes_for :images, :allow_destroy => :true
    accepts_nested_attributes_for :videos, :allow_destroy => :true
    accepts_nested_attributes_for :question, :allow_destroy => :true, :reject_if => proc { |attributes| attributes['description'].blank? }
    accepts_nested_attributes_for :design_files, :allow_destroy => :true

    scope :first_step, where(:name=> "Project Overview")
    scope :not_labels, where(:label=> nil)

  	validates :name, :presence => true

    after_update :check_decision

    searchable do
      text :description, :stored => true do
        strip_tags(description)
      end
    end

    def published_on_formatted
      published_on.strftime("%m/%d/%Y %H:%M:%S")
    end

    def published_on_date
      published_on.strftime("%m/%d/%Y")
    end

    def published_on_time
      published_on.strftime("%I:%M %p")
    end

    def first_image
        images.order("position ASC").first if images
    end

    def last_image
        images.order("position ASC").last if images
    end

    def has_video?
      return !video.blank?
    end

    def remix?
      return project.is_remix?
    end

    def has_unanswered_question?
      if question && !question.answered
        return true
      else
        return false
      end
    end

   def check_decision
      if question && question.answered && question.decision && (question.decision.description=="I decided to ..." || question.decision.description.blank?)
            question.decision.destroy
      end
   end

  # test whether step is a label
  def is_label?
    return label==true
  end

   # add users to steps after creating steps_users table
   def add_step_users
    step_user = User.find(user_id)
    users << step_user
   end

   # returns a list of authors for the project
   def authors
    author_list = ""
    num_users = users.count
    users.each_with_index do |user, index|
      logger.debug('#{index}')
      if num_users > 2 && index == num_users-1
        author_list += ' , and '
      end

      author_list += user.username

      if num_users == 2 && index == 0
        author_list += ' and '
      elsif num_users > 2 && index != num_users-2 && index != num_users-1 
        author_list += ' , '
      end
    end
    return author_list
   end

  # set original authors to steps of projects that are remixes - only for projects that only have one author!
  def set_original_authors
    original_author = Project.find(project.remix_ancestry).users.first
    update_attributes(:original_authors => Array.new << original_author.id)
  end

  # new authors in a remix project (authors that aren't part of the original_authors)
  def new_authors
    if original_authors
      user_ids =  users.pluck(:id) - original_authors
      new_authors_array = Array.new
      
      if user_ids.length > 0
        user_ids.each do |user_id|
          new_authors_array << User.find(user_id)
        end
      end
      return new_authors_array
    else
      return users
    end
  end

  # editing_authors - checks what authors are currently editing the step
  # returns the user object of the editing author
  def editing_authors
    conflict_authors_array = Array.new
    edits.each do |edit|
      if edit.started_editing_at.present?
        conflict_authors_array << edit.user
      end
    end
    return conflict_authors_array
  end

  # generate a news item
  def generate_news_item
    news_step_id = self.id
    news_title = self.name
    if self.project.title.downcase.include? "website"
      news_type = "website"
    else
      news_type = "mobile"
    end
    News.create(:title => news_title, :step_id => news_step_id, :news_type => news_type)
  end

  # generate the path to a step's thumbnail image (used for logger)
  def first_image_path
    first_image = self.first_image
    if first_image.present?
      if first_image.image_path.present?
        return first_image.image_path_url
      elsif first_image.s3_filepath.present?
        return first_image.s3_filepath
      end
    end
  end

  ######## SCRIPTS ########

  # add edits
  def add_edits
      Edit.create(step_id: id, project_id: project_id, user_id: user_id)
  end

  def self.description_to_csv
    CSV.generate do |csv|
      all.each do |step|
        if step.description && step.description.present?
          csv << [ActionView::Base.full_sanitizer.sanitize(step.description).to_s.gsub(/\r/,"").gsub(/\n/,"").gsub(/\&nbsp;/,"").gsub(/\t/,"")]
        end
      end
    end
  end

end
