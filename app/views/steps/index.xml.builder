xml.instruct!
xml.project do 
	xml.project_name @project['title']
	xml.steps do 
		@project.steps.each do |step|
			xml.step do
				xml.step_name step['name']
				xml.step_description step['description'].gsub(/<.+?>/, '')
				xml.step_images do
					step.images.each do |image|
						xml.step_image image.file
					end
				end
			end
	end
end
end