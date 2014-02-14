class AddFeaturedColumnsToProjects < ActiveRecord::Migration
  def change
  	add_column :projects, :featured, :boolean
  	add_column :projects, :featured_on_date, :datetime
  end
end
