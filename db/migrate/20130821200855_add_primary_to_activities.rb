class AddPrimaryToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :primary, :boolean
  end
end
