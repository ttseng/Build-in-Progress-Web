class User < ActiveRecord::Base
  include PublicActivity::Model
  include PublicActivity::Common
  activist

  extend FriendlyId
  friendly_id :username
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :token_authenticatable, :confirmable, :lockable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :username, :avatar, :about_me, :notifications_viewed_at
  # attr_accessible :title, :body
  has_many :collections, :dependent => :destroy

  has_and_belongs_to_many :projects
  before_destroy { 
    projects.clear
  }
  
  has_many :edits

  # media files
  has_many :images
  has_many :videos
  has_many :sounds

  # Favorite projects
  has_many :favorite_projects, :dependent => :destroy # just the 'relationships'
  has_many :favorites, :through => :favorite_projects, :source=> :project # projects a user favorites

  accepts_nested_attributes_for :projects

  mount_uploader :avatar, AvatarUploader

  validates :username, :presence => true
  validates :email, :presence => true

  before_save :ensure_authentication_token

  acts_as_followable
  acts_as_follower

  def skip_confirmation!
    self.confirmed_at = Time.now
  end

  def last_updated_date
    if !projects.blank?
      time_ago_in_words(updated_at)
    else
      time_ago_in_words(last_sign_in_at)
    end
  end

  # only activity on the user's projects
  def user_project_notifications
    activities_as_recipient.where("owner_id != recipient_id OR recipient_id IS NULL OR owner_id IS NULL").where(:primary=>true).where("trackable_type !=?", "Step").order("created_at DESC")
  end

  def new_user_project_notifications
    return user_project_notifications.where(:viewed=>false)
  end

  # all activity (including activity on the user's projects + activity on comments they follow)
  def all_notifications
    activities_as_recipient.where("owner_id != recipient_id OR recipient_id IS NULL OR owner_id IS NULL").where("trackable_type !=?", "Step").order("created_at DESC")
  end

  # notifications (not activities)
  def all_new_notifications
    activities_as_recipient.where(:viewed=>false).where("owner_id != recipient_id").where("trackable_type != ?", "Step").order("created_at DESC")
  end

  def last_few_notifications
    return all_notifications.where("created_at > ?", 1.month.ago).limit(4)
  end

  # activities of the current user on other user's projects
  def user_activity
    activities_as_owner.where("owner_id != recipient_id OR recipient_id IS NULL OR owner_id IS NULL").order("created_at DESC")
  end

  # returns (commentable) activity on steps made after the user commented on that step
  def followed_comments
    activities_as_recipient.comments.where(:primary=>false)
  end

end