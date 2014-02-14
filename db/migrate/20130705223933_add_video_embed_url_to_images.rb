class AddVideoEmbedUrlToImages < ActiveRecord::Migration
  def change
    add_column :images, :video_embed_url, :string
  end
end
