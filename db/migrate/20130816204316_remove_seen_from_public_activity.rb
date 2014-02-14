class RemoveSeenFromPublicActivity < ActiveRecord::Migration
  def up
  	remove_column :activities, :seen
  end

  def down
  end
end
