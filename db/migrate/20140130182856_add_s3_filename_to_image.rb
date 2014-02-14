class AddS3FilenameToImage < ActiveRecord::Migration
  def change
    add_column :images, :s3_filepath, :string
  end
end
