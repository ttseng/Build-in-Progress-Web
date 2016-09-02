class ChangeCollectionDescriptionToText < ActiveRecord::Migration
  def up
  	change_column :collections, :description, :text
  end

  def down
  	change_column :collections, :description, :string
  end
end
