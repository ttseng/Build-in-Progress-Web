class CreateImageUrls < ActiveRecord::Migration
  def change
    create_table :image_urls do |t|
      t.integer :project_id
      t.integer :step_id
      t.string :url

      t.timestamps
    end
  end
end
