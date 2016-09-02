class AddCoverImageToProject < ActiveRecord::Migration
  def change
    add_column :projects, :cover_image, :integer
  end
end
