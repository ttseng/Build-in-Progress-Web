class User < ActiveRecord::Base
  include PublicActivity::Model
  include PublicActivity::Common
  include ActionView::Helpers::SanitizeHelper

  activist

  extend FriendlyId
  friendly_id :username
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :token_authenticatable, :confirmable, :lockable, :omniauthable, :omniauth_providers => [:google_oauth2, :village]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :username, :avatar, :about_me, :notifications_viewed_at, :provider, :uid, :confirmed_at, :access_token, :admin, :last_sign_in_at, :sign_in_count, :banned

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
  validates_uniqueness_of :username

  before_save :ensure_authentication_token

  acts_as_followable
  acts_as_follower

  # Settings
  has_settings do |s|
    s.key :email, :defaults => {:comments => true, :featured => true, :collaborator => true, 
      :favorited => true, :collectify_owner => true, :collectify_recipient => true, :followed => true, :remixed => true}
  end

  fields = (User.attribute_names - ["username, about_me"]).map{|o| o.to_sym}

  searchable :ignore_attribute_changes_of => fields do
    text :about_me, :stored => true do
       strip_tags(about_me)
    end
  end

  def admin?
    return self.admin == true
  end

    
  # get attributes from village and create user account
  def self.from_village_omniauth(auth)
    provider = auth[:provider]
    uid = auth[:uid].to_s
    where("provider = ? and uid = ?", provider, uid).first_or_initialize do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.username = auth.info.name
      user.email = auth.info.email
      user.skip_confirmation!
      if user.save
        Rails.logger.info('created user')
      else
        # username or email exists, redirect to home page with notice
        Rails.logger.info(user.errors.inspect)
      end
    end
  end

  # get attributes from google and create user
  def self.from_google_omniauth(auth)
    provider = auth[:provider]
    uid = auth[:uid].to_s
    where("provider = ? and uid = ?", provider, uid).first_or_initialize do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.username = auth.info.email.split("@").first
      user.email = auth.info.email
      user.skip_confirmation!
      if user.save
        Rails.logger.info('created user')
      else
        # username or email exists, redirect to home page with notice
        Rails.logger.info(user.errors.inspect)
      end
    end
  end

  def self.new_with_session(params, session)
    if session["devise.user_attributes"]
      new(session["devise.user_attributes"], without_protection: true) do |user|
        user.attributes = params
        user.valid?
      end
    end
  end

  def confirmation_required?
    super && !provider.present?
  end

  def password_required?
    super && provider.blank?
  end

  def from_village?
    return !self.uid.blank?
  end

  def email_required?
    super && provider.blank?
  end

  def update_with_password(params, *options)
    if encrypted_password.blank?
      update_attributes(params, *options)
    else
      super
    end
  end

  def skip_confirmation!
    self.confirmed_at = Time.now
  end

  def last_updated_date
    if !projects.blank?
      time_ago_in_words(updated_at)
    elsif last_sign_in_at
      time_ago_in_words(last_sign_in_at)
    else
      time_ago_in_words(created_at)
    end
  end

  # returns either the user's avatar profile image or the default image
  def profile_img
    if avatar.present?
      return ActionController::Base.helpers.image_tag(avatar_url(:thumb))
    else
      return ActionController::Base.helpers.image_tag("default_avatar.png")
    end
  end

  # only activity on the user's projects
  def user_project_notifications
    activities_as_recipient.where("owner_id != recipient_id OR recipient_id IS NULL OR owner_id IS NULL").where(:primary=>true).where("trackable_type !=?", "Step").order("created_at DESC").public_activities
  end

  def new_user_project_notifications
    return activities_as_recipient.where("owner_id != recipient_id OR recipient_id IS NULL OR owner_id IS NULL").where(:primary=>true).where("trackable_type !=?", "Step").order("created_at DESC").where(:viewed=>false).public_activities
  end

  # all activity (including activity on the user's projects + activity on comments they follow)
  def all_notifications
    activities_as_recipient.where("owner_id != recipient_id OR recipient_id IS NULL OR owner_id IS NULL").where("trackable_type !=?", "Step").order("created_at DESC").public_activities
  end

  # notifications (not activities)
  def all_new_notifications
    activities_as_recipient.where(:viewed=>false).where("owner_id != recipient_id OR owner_id IS NULL").where("trackable_type != ?", "Step").order("created_at DESC").public_activities
  end

  def last_few_notifications
    return all_notifications[0...3]
  end

  # activities of the current user on other user's projects
  def user_activity
    activities_as_owner.where("owner_id != recipient_id OR recipient_id IS NULL OR owner_id IS NULL").order("created_at DESC")
  end

  # returns unique set of comments left by user
  def comments
    activities_as_owner.where(:trackable_type=>"Comment").select("DISTINCT ON (trackable_id) *")
  end

  # returns (commentable) activity on steps made after the user commented on that step
  def followed_comments
    activities_as_recipient.comments.where(:primary=>false)
  end

  def followers_activity
    PublicActivity::Activity.order("created_at desc").where(owner_id: self.following_users, owner_type: "User")
  end

  # SCRIPTS
  # add_email_notifications: add email notifications for users that have an email
  def add_email_notifications
    if email.present?
      settings(:email).update_attributes! :comments => true, :featured => true, :collaborator => true,
      :favorited => true, :collectify_recipient => true, :collectify_owner => true, :followed => true, :remixed => true    
    else
      settings(:email).update_attributes! :comments => false, :featured => false, :collaborator => false,
      :favorited => false, :collectify_recipient => false, :collectify_owner => false, :followed => false, :remixed => false   
    end
  end

  def remove_email_notifications
    settings(:email).update_attributes! :comments => false, :featured => false, :collaborator => false,
      :favorited => false, :collectify_recipient => false, :collectify_owner => false, :followed => false, :remixed => false    
  end

  def send_survey
    SurveyWorker.perform_async(self.id)
  end

  # BAN USERS!
  def active_for_authentication?
    super && !self.banned
  end

end