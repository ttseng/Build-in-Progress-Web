class AddVideoThumbnailToImage < ActiveRecord::Migration
  def change
    add_column :images, :video_thumbnail, :boolean
  end
end
