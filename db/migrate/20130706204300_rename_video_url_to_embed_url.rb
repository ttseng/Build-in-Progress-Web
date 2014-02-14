class RenameVideoUrlToEmbedUrl < ActiveRecord::Migration
  def up
  	rename_column :videos, :url, :embed_url
  end

  def down
  end
end
