class DesignFile < ActiveRecord::Base

  attr_accessible :project_id, :step_id, :user_id, :design_file_path


  belongs_to :step
  belongs_to :project
  belongs_to :user, :touch=> true

  mount_uploader :design_file_path, DesignFilePathUploader

  validates :design_file_path, :presence => true

  # returns the filename of the design file (including extension) from the design_file_path url
  def filename
  	self.design_file_path.split('/').pop()
  end
end
