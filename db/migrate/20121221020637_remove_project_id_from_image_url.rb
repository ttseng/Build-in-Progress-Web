class RemoveProjectIdFromImageUrl < ActiveRecord::Migration
  def up
    remove_column :image_urls, :project_id
  end

  def down
    add_column :image_urls, :project_id, :integer
  end
end
