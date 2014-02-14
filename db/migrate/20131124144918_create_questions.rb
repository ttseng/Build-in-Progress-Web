class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.belongs_to :step	
      t.string :description
      t.boolean :solved, :default=> false

      t.timestamps
    end
  end
end
