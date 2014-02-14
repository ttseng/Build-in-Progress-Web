class RemoveEmbedCodeFromVideos < ActiveRecord::Migration
  def up
    remove_column :videos, :embed_code
  end

  def down
    add_column :videos, :embed_code, :string
  end
end
