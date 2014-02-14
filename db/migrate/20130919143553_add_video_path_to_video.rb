class AddVideoPathToVideo < ActiveRecord::Migration
  def change
    add_column :videos, :video_path, :string
  end
end
