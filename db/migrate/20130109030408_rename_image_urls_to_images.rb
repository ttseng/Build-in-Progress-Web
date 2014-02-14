class RenameImageUrlsToImages < ActiveRecord::Migration
  def change
  	rename_table :image_urls, :images
  end

end
