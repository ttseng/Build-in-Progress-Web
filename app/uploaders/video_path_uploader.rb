require 'carrierwave/processing/mime_types'
require 'rubygems'
require 'mini_exiftool'

class VideoPathUploader < CarrierWave::Uploader::Base
  include CarrierWave::Video
  include CarrierWave::Video::Thumbnailer
  include CarrierWave::MimeTypes

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  orientation = 0

  # Choose what kind of storage to use for this uploader:
  # storage :file
  storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  process :encode

  def encode
    video = MiniExiftool.new(@file.path)
    orientation = video.rotation
    model.rotation = orientation

    Rails.logger.debug("orientation: #{orientation}")
    Rails.logger.debug("video wxh #{video.imagewidth} #{video.imageheight}")

    if orientation == 90 && video.imagewidth.to_f > video.imageheight.to_f
      Rails.logger.debug("rotating video")
      aspect_ratio = video.imageheight.to_f / video.imagewidth.to_f 
      encode_video(:mp4, audio_codec: "aac", custom: "-strict experimental -q:v 5 -preset slow -g 30 -vf transpose=1 -vsync 2", aspect: aspect_ratio)
    elsif orientation == 180 && video.imagewidth.to_f > video.imageheight.to_f
      Rails.logger.debug('180')
      aspect_ratio = video.imageheight.to_f / video.imagewidth.to_f 
      encode_video(:mp4, audio_codec: "aac",custom: "-strict experimental -q:v 5 -preset slow -g 30 -vf transpose=2,transpose=2 -vsync 2", aspect: aspect_ratio)
    elsif orientation == 270 && video.imagewidth.to_f > video.imageheight.to_f
      Rails.logger.debug('270')
      aspect_ratio = video.imageheight.to_f / video.imagewidth.to_f 
      encode_video(:mp4, audio_codec: "aac", custom: "-strict experimental -q:v 5 -preset slow -g 30 -vf transpose=2 -vsync 2", aspect: aspect_ratio)
    else
      aspect_ratio = video.imagewidth.to_f / video.imageheight.to_f
      encode_video(:mp4, audio_codec: "aac",custom: "-strict experimental -q:v 5 -preset slow -g 30 -vsync 2", aspect: aspect_ratio)
    end

    instance_variable_set(:@content_type, "video/mp4")
    :set_content_type_mp4 
  end

  def filename
    result = [original_filename.gsub(/\.\w+$/, ""), 'mp4'].join('.') if original_filename
    result
  end

  # version :webm do
  #   process :encode_video => [:webm]
  #   process :set_content_type_webm
  #   def full_filename(for_file)
  #     "#{File.basename(for_file, File.extname(for_file))}.webm"
  #   end
  # end

  version :thumb do 
    process thumbnail: [{format: 'png', quality: 10, size: 0, strip: false, logger: Rails.logger}]
    def full_filename for_file
      png_name for_file, version_name, "jpeg"
    end
    process :set_content_type_jpeg

    # process thumbnail: [{format: 'png', quality: 10, size: 0, strip: false, logger: Rails.logger}]
    # def full_filename for_file
    #    png_name for_file, version_name
    # end
    # process :set_content_type_png
    # # process resize_to_limit: [105, 158]
  end

  version :square_thumb do
    process thumbnail: [{format: 'png', quality: 10, size: 105, strip: false, logger: Rails.logger}]
    def full_filename for_file
      png_name for_file, version_name, "jpeg"
    end
    process :set_content_type_jpeg

    # process thumbnail: [{format: 'png', quality: 10, size: 105, strip: false, logger: Rails.logger}]
    # def full_filename for_file
    #   png_name for_file, version_name
    # end
    # process :set_content_type_png
    # process resize_to_fill: [105, 105]
  end

  def png_name for_file, version_name, format
    %Q{#{version_name}_#{for_file.chomp(File.extname(for_file))}.#{format}}
  end

  def set_content_type_mp4(*args)
    Rails.logger.debug "#{file.content_type}"
    self.file.instance_variable_set(:@content_type, "video/mp4")
  end

  def set_content_type_webm(*args)
    Rails.logger.debug "#{file.content_type}"
    self.file.instance_variable_set(:@content_type, "video/webm")
  end

  def set_content_type_jpeg(*args)
    self.file.instance_variable_set(:@content_type, "image/jpeg")
  end

  def set_content_type_png(*args)
    Rails.logger.debug "#{file.content_type}"
    self.file.instance_variable_set(:@content_type, "image/png")
  end

end
