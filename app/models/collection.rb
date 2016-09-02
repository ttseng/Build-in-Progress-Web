class Collection < ActiveRecord::Base
  include PublicActivity::Common
  include ActionView::Helpers::SanitizeHelper
  extend FriendlyId
  friendly_id :name, use: [:slugged, :history]

  belongs_to :user, :touch=> true
  default_scope -> { order('updated_at DESC') }
  validates :user_id, presence: true

  has_many :collectifies, :dependent => :destroy
  has_many :projects, :through => :collectifies

  attr_accessible :description, :name, :published, :image, :challenge, :privacy

  mount_uploader :image, CollectionImagePathUploader

  validates :name, presence: true, uniqueness: true

  scope :published, where(:published=>true)

  scope :private_collections, where(:privacy => "private")
  scope :unlisted_collections, where(:privacy => "unlisted")
  scope :public_collections, where(:privacy => "public")

  searchable do
    text :description, :stored => true do
      strip_tags(description)
    end
    boolean :published
  end

  def published?
    published = false
    # collections are published if they have a name and more than 1 project
    if !name.starts_with?("Untitled")
      if projects.public_projects.count > 0
        published = true
      end
    end
    return published
  end

  def challenge?
    self.challenge
  end

  def remove!(project)
    collectifies.where(project_id: project.id).first.delete
    if published?
      update_attributes(:published=>true)
    else
      update_attributes(:published=>false)
    end
  end

  def public?
    self.privacy == "public"
  end

  def private?
    self.privacy == "private"
  end

  def unlisted?
    self.privacy == "unlisted"
  end

  # an array of users that includes the author of the collection and authors of
  # any of the projects in a colelction
  def collection_users
    users = Array.new
    users << self.user
    self.projects.each do |project|
      project.users.each do |user|
        unless users.include? user
          users << user
        end
      end
    end
    return users
  end

end
