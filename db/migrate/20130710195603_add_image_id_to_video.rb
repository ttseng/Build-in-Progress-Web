class AddImageIdToVideo < ActiveRecord::Migration
  def change
    add_column :videos, :image_id, :integer
  end
end
