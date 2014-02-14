class CreateDesignFiles < ActiveRecord::Migration
  def change
    create_table :design_files do |t|
      t.integer :project_id
      t.integer :step_id
      t.string :url

      t.timestamps
    end
  end
end
