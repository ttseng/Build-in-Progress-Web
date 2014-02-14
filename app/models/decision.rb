class Decision < ActiveRecord::Base
  attr_accessible :description, :question_id
  belongs_to :question

  after_update :check_blank

   def check_blank
  	if description.blank?
  		self.destroy
  	end
  end
  
end
