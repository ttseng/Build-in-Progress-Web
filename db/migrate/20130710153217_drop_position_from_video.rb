class DropPositionFromVideo < ActiveRecord::Migration
  def up
  	 remove_column :videos, :position
  end

  def down
  end
end
