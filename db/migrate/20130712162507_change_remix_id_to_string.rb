class ChangeRemixIdToString < ActiveRecord::Migration
  def up
  	change_column :projects, :remix_id, :string
  end

  def down
  end
end
