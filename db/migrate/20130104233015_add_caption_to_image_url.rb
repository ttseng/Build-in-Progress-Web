class AddCaptionToImageUrl < ActiveRecord::Migration
  def change
    add_column :image_urls, :caption, :string
  end
end
