class Edit < ActiveRecord::Base
  attr_accessible :started_editing_at, :user_id, :project_id, :step_id, :temp
  belongs_to :user
  belongs_to :step
  belongs_to :project

  # reset the started editing at for an edit to nil
  def reset_started_editing_at
  	update_attributes(:started_editing_at => nil)
  end
  
end
