class RenameSoundcloudToSound < ActiveRecord::Migration
  def change
  	rename_table :soundclouds, :sounds
  end

end
