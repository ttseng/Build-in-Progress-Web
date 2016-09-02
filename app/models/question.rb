class Question < ActiveRecord::Base
  include PublicActivity::Common
  attr_accessible :answered, :description, :step_id, :decision_attributes, :featured

  belongs_to :step
  has_one :decision, :dependent => :destroy

  accepts_nested_attributes_for :decision

  after_create :touch_project
  after_update :check_blank

  scope :unanswered, where(:answered=>false)
  scope :featured, where(:featured => nil)
  scope :answered, where(:answered=>true)

  def touch_project
  	step.project.touch
  end

  def check_blank
  	if description.blank?
  		self.destroy
  	end
  end

  def answered?
    return self.answered
  end

end
