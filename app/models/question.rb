class Question < ActiveRecord::Base
  attr_accessible :answered, :description, :step_id, :decision_attributes
  belongs_to :step
  has_one :decision, :dependent => :destroy

  accepts_nested_attributes_for :decision

  after_create :touch_project
  after_update :check_blank

  def touch_project
  	step.project.touch
  end

  def check_blank
  	if description.blank?
  		self.destroy
  	end
  end

end
