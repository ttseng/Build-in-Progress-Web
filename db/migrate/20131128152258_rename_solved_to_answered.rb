class RenameSolvedToAnswered < ActiveRecord::Migration
  def change
  	rename_column :questions, :solved, :answered
  end
end
