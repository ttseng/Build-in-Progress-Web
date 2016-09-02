class ProjectLogWorker
	include Sidekiq::Worker 

	# log the current state of a project
	def perform(project_id)
		if Project.exists?(project_id)
			@project = Project.find(project_id)
			s3 = AWS::S3.new(:access_key_id => ENV['AWS_ACCESS_KEY_ID'], :secret_access_key => ENV['AWS_ACCESS_KEY'])
    		key = "logs/" + project_id.to_s + ".json"
    		project_json = []

    		obj = s3.buckets[ENV['AWS_BUCKET']].objects[key]
    		if obj.exists?
      			# get the current log file if it exists and append to it
      			puts "fetching existing json file"
      			project_json = JSON.parse(obj.read)
    		end
    
		    # only create log for new projects (not existing projects)
		    if !obj.exists?
		      # store all steps in the log file
		      steps_json = []
		      @project.steps.order(:position).each do |step|
		        #step.as_json(:only => [:id, :name, :position, :ancestry, :label, :label_color], :method => :first_image_path)
		        step_json = {
		          "id" => step.id,
		          "name" => step.name,
		          "position" => step.position,
		          "ancestry" => step.ancestry
		        }
		        # step_json["thumbnail_id"] = step.first_image.id if step.first_image.present?
		        step_json['label'] = step.label if step.label.present?
		        step_json['label_color'] = step.label_color if step.label.present?

		        steps_json << step_json
		      end

		      # create new json file
		      project_json = {
		        "data" => [
		          "updated_at" => @project.updated_at.to_s, 
		          "title" => @project.title,
		          "word_count" => @project.word_count,
		          "image_count" => @project.image_count,
		          "steps" => steps_json
		        ]
		      }      
		      puts '===========ADDING LOG==========='
		      s3.buckets[ENV['AWS_BUCKET']].objects[key].write(project_json.to_json)
		    else
		           # store all steps in the log file
		      steps_json = []
		      @project.steps.order(:position).each do |step|
		        #step.as_json(:only => [:id, :name, :position, :ancestry, :label, :label_color], :method => :first_image_path)
		        step_json = {
		          "id" => step.id,
		          "name" => step.name,
		          "position" => step.position,
		          "ancestry" => step.ancestry
		        }
		        # step_json["thumbnail_id"] = step.first_image.id if step.first_image.present?
		        step_json['label'] = step.label if step.label.present?
		        step_json['label_color'] = step.label_color if step.label.present?

		        steps_json << step_json
		      end
		      
		      # append project update to existing json
		      update_json = {
		        "updated_at" => @project.updated_at.to_s,
		        "title" => @project.title,
		        "word_count" => @project.word_count,
		        "image_count" => @project.image_count,
		        "steps" => steps_json
		      }

		      # puts "update_json #{update_json}"

		      project_json = {
		        "data" => project_json["data"] << update_json
		      }

		      # puts "project_json.to_json #{project_json.to_json}"
		      puts '===========ADDING LOG==========='
		      s3.buckets[ENV['AWS_BUCKET']].objects[key].write(project_json.to_json)
				end
			end
		end
			
end