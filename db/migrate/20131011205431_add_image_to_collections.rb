class AddImageToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :image, :string
  end
end
