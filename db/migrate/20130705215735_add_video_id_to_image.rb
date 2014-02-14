class AddVideoIdToImage < ActiveRecord::Migration
  def change
    add_column :images, :video_id, :integer
  end
end
