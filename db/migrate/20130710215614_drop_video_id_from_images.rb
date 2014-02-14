class DropVideoIdFromImages < ActiveRecord::Migration
  def up
  	remove_column :images, :video_id
  end

  def down
  end
end
