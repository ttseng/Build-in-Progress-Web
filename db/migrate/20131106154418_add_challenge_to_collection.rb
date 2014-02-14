class AddChallengeToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :challenge, :boolean
  end
end
