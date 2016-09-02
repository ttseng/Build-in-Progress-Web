require 'rufus/scheduler'
require "net/http"

scheduler = Rufus::Scheduler.new
	
  # delete images that have been uploaded
  scheduler.every '12h' do
  	 s3 = AWS::S3.new(:access_key_id => ENV['AWS_ACCESS_KEY_ID'], :secret_access_key => ENV['AWS_ACCESS_KEY'])
     image_count = 0

     # delete images that have been saved from the uploaded folder
  	 Image.where("s3_filepath is NOT NULL").each do |image|
  	 	if image.image_path && image.updated_at < 5.minute.ago
        puts "found image to delete #{image.s3_filepath}"
  	 		foldername = image.s3_filepath.split("/")[5]
  	 		folder_path = 'uploads/' + foldername
        puts "folder path: #{folder_path}"
  	 		s3.buckets[ENV['AWS_BUCKET']].objects.with_prefix(folder_path).delete_all
        image_count = image_count + 1
  	 		image.update_attributes(:s3_filepath => nil)
  	 	end
  	 end

     # delete images that were unsaved in a step
     Image.where(:step_id => -1).each do |image|
      if image.image_path && image.updated_at > 24.hours.ago 
        image.destroy
       image_count = image_count + 1
      end
     end

     puts "images deleted = #{image_count}"

   # destroy empty images
   Image.where("image_path IS NULL").where("s3_filepath IS NULL").destroy_all
 end
