class QuestionsController < ApplicationController
	def create
		@question = Question.find(params[:question_id])
		@question.step.project.touch
	end

	def update
		@question = Question.find(params[:question_id])
		@question.step.project.touch
	end

end