class AddUserAssociations < ActiveRecord::Migration
  def change
  	add_column :steps, :user_id, :integer
  end
end
