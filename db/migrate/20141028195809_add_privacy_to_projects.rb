class AddPrivacyToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :privacy, :string
  end
end
