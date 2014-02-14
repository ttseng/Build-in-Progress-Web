class RemoveVideoEmbedUrlFromImages < ActiveRecord::Migration
  def up
  	remove_column :images, :video_embed_url
  end

  def down
  end
end
