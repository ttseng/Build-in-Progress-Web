module StepsHelper

	def branching(steps, currentStep)
		steps.map do |step, branched_steps|
			#render(step) + content_tag(:div, branching(branched_steps, step), :class=>"nested_messages")
			render(:partial=>"step", :locals => {:step=> step, :currentStep=> currentStep, :steps => steps}) + content_tag(:div, branching(branched_steps, currentStep), :class=>"branchedStep")
		end.join.html_safe
	end

	# get the tree structure of process map
	def getBranches
		currentBranchArray = Array.new # placeholder for holding steps from a given branch 
		@allBranches = Hash.new # holds tree structure for entire process map
		@mapping = Hash.new # maps branch ancestry to branch number
		mapIndex = 0 # placeholder for branch number

		(0..@ancestry.length-1).each do |index|
			if @allBranches.has_key?(@ancestry[index])
				currentValues = @allBranches[@ancestry[index]]
				currentValues.push(index)
				@allBranches[@ancestry[index]] = currentValues
			else
				@mapping[@ancestry[index]] = mapIndex
				@allBranches[@ancestry[index]] = [index]
				mapIndex = mapIndex + 1
			end
		end

		# change the format of @allBranches to [branchNumber: [steps]]
		@allBranches = Hash[@allBranches.map {|k, v| [@mapping[k],v]}]
	end

	# get parent of an element
	def getParent(stepAncestry)
		 slashLocation = stepAncestry.rindex("/")
          if slashLocation != nil
            stepAncestry = stepAncestry[slashLocation+1, stepAncestry.length]
          end
         return stepAncestry
	end
	
end