class ChartsController < ApplicationController
	# users: cumulative number of users
	def users
		sum = 0
		render json: User.where("sign_in_count > ?", 0).group_by_month(:created_at).count.map { |x,y| { x => (sum+=y)} }.reduce({}, :merge)
	end

	# users_by_month: number of user registrations by month
	def users_by_month
		render json: User.where("sign_in_count > ?", 0).group_by_month(:created_at).count
	end

	# steps: cumulative number of steps created
	def steps
		sum = 0
		render json: Step.group_by_month(:created_at).count.map { |x,y| { x => (sum+=y)} }.reduce({}, :merge)
	end

	# steps_by_month: number of steps created per month
	def steps_by_month
		render json: Step.group_by_month(:created_at).count
	end

	# comments: cumulative comments created per month
	def comments
		sum = 0 
		render json: Comment.group_by_month(:created_at).count.map { |x,y| { x => (sum+=y)} }.reduce({}, :merge)
	end

	# comments_by_month: number of commments created per month
	def comments_by_month
		render json: Comment.group_by_month(:created_at).count
	end


end
