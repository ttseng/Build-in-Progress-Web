class AddSoundIdToImage < ActiveRecord::Migration
  def change
    add_column :images, :sound_id, :integer
  end
end
