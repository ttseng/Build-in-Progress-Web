class Collection < ActiveRecord::Base
  include PublicActivity::Common

  belongs_to :user, :touch=> true
  default_scope -> { order('updated_at DESC') }
  validates :user_id, presence: true

  has_many :collectifies, :dependent => :destroy
  has_many :projects, :through => :collectifies

  attr_accessible :description, :name, :published, :image, :challenge

  mount_uploader :image, CollectionImagePathUploader

  validates :name, presence: true
  validates :description, length: {maximum: 200}

  scope :published, where(:published=>true)

  def published?
    published = false
    # collections are published if they have a name and more than 1 project
    if !name.starts_with?("Untitled")
      if projects.published.count > 0
        published = true
      end
    end
    return published
  end

  def remove!(project)
    collectifies.where(project_id: project.id).first.delete
    if published?
      update_attributes(:published=>true)
    else
      update_attributes(:published=>false)
    end
  end
end
