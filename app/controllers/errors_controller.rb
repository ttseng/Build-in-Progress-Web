class ErrorsController < ApplicationController
	
	def show
		render status_code.to_s, :status => status_code
	end

	def unauthorized
		render "401"
	end

	protected

	def status_code
		params[:code] || 500
	end

end
