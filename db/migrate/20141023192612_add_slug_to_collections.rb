class AddSlugToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :slug, :string
    add_index :collections, :slug
  end
end
