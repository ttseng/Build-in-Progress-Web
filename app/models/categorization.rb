class Categorization < ActiveRecord::Base
  belongs_to :project
  belongs_to :category

  attr_accessible :category_id, :project_id
end
