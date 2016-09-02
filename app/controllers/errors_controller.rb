class ErrorsController < ApplicationController
	
	def show
		Rails.logger.debug("ERROR WITH STATUS #{status_code.to_s}")
		render status_code.to_s, :status => status_code
	end

	def unauthorized
		render "401"
	end

	protected

	def status_code
		Rails.logger.debug("STATUS CODE: #{params[:code]}")
		params[:code] || 500
	end

end
