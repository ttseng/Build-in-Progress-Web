require 'new_relic/agent/method_tracer'
require 'mini_exiftool'

class ImagePathUploader < CarrierWave::Uploader::Base
  include ::NewRelic::Agent::MethodTracer

  # Include RMagick or MiniMagick support:
    include CarrierWave::MiniMagick

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
    include Sprockets::Helpers::RailsHelper
    include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  # storage :file
  storage :fog

  include CarrierWave::MimeTypes
  process :set_content_type

  process :fix_exif_rotation

  def fix_exif_rotation #this is my attempted solution
    manipulate! do |img|
      img.tap(&:auto_orient)
    end
  end

  # process :rotate_img

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
     "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

    # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def is_landscape?(new_file)
      image = ::MiniMagick::Image::read(File.binread(@file.file))
      image[:width] >= image[:height]
  end

  def is_portrait?(new_file)
    !is_landscape?(new_file)
  end

  def not_small_image?(new_file)
     image = ::MiniMagick::Image::read(File.binread(@file.file))
     image[:width] >= 500 || image[:height] >= 500
   end

 def add_square_thumb
  recreate_versions!(:square_thumb)
 end
 add_method_tracer :add_square_thumb, 'Custom/add_square_thumb'

 def add_preview_large
  recreate_versions!(:preview_large)
 end
 add_method_tracer :add_preview_large, 'Custom/add_preview_large'

# def rotate_img
#   if model.rotation.present? && !model.rotated
#     Rails.logger.debug("********IN ROTATE_IMG IN IMAGE_PATH_UPLOADER FOR #{model.id}")
#       manipulate! do |img|
#         img.rotate model.rotation
#         img
#       end
#       model.update_column("rotated", nil)
#       model.update_column("rotation", nil)
#   end  
# end

process :resize_to_limit => [900, 900] 

add_method_tracer :resize_to_limit, 'Custom/resize_to_limit'

version :preview do
  self.class.trace_execution_scoped(['Custom/create_preview']) do 
    process :resize_to_fill => [380,285]
  end
end

version :preview_large do
  self.class.trace_execution_scoped(['Custom/create_preview_large']) do 
    process :resize_to_fill => [760,570]
  end
end

version :thumb do
  self.class.trace_execution_scoped(['Custom/thumb']) do 
    process :resize_to_limit => [105,158]
  end
end

version :square_thumb do
  self.class.trace_execution_scoped(['Custom/square_thumb']) do 
    process :resize_to_fill => [105, 105]
  end
end

end
