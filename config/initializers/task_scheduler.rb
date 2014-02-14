require 'rufus/scheduler'
require "net/http"
scheduler = Rufus::Scheduler.new
 
	if Rails.env.production?
		# ping heroku server to prevent it from going to sleep automatically
	  scheduler.every '50m' do
	     require "net/http"
	     require "uri"
	     url = 'http://bip-android-test.herokuapp.com'
	     Net::HTTP.get_response(URI.parse(url))
	     puts 'pinging bip-android-test'
	  end
	end
	
  # delete images that have been uploaded
  scheduler.every '12h' do
  	 s3 = AWS::S3.new(:access_key_id => ENV['AWS_ACCESS_KEY_ID'], :secret_access_key => ENV['AWS_ACCESS_KEY'])
  	 Image.where("s3_filepath is NOT NULL").each do |image|
  	 	if image.image_path && image.updated_at < 30.minute.ago
  	 		foldername = image.s3_filepath.split("/")[5]
  	 		folder_path = 'uploads/' + foldername
  	 		s3.buckets[ENV['AWS_BUCKET']].objects.with_prefix(folder_path).delete_all
  	 		image.update_attributes(:s3_filepath => nil)
  	 	end
  	 end
   end


