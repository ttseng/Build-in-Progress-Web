class CreateSoundclouds < ActiveRecord::Migration
  def change
    create_table :soundclouds do |t|
      t.string :embed_url
      t.integer :project_id
      t.integer :step_id
      t.boolean :saved
      t.integer :image_id
      t.string :thumbnail_url
      t.timestamps
    end
  end
end
