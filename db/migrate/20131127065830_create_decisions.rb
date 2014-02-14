class CreateDecisions < ActiveRecord::Migration
  def change
    create_table :decisions do |t|
      t.belongs_to :question
      t.string :description

      t.timestamps
    end
  end
end
