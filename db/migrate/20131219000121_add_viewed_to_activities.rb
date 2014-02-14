class AddViewedToActivities < ActiveRecord::Migration
  def change
 	add_column :activities, :viewed, :boolean, :default => false
  end
end
