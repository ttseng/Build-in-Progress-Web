class AddPrivacyToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :privacy, :string
  end
end
