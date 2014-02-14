class AddOriginalUsersToStep < ActiveRecord::Migration
  def change
    add_column :steps, :original_authors, :text
  end
end
