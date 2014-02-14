class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.string :url
      t.string :embed_code
      t.integer :project_id
      t.integer :step_id
      t.integer :position
      t.boolean :saved

      t.timestamps
    end
  end
end
