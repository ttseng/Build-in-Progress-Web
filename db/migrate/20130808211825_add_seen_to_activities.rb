class AddSeenToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :seen, :boolean
  end
end
