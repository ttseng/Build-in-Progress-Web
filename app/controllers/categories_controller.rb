class CategoriesController < ApplicationController
  def index
    @categories = Category.all

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.json { render :json => @collections }
    end
  end

  # GET /categories/1
  # GET /categories/1.json
  def show
    @category = Category.find(params[:id])
    @all_projects = @category.projects.order("updated_at DESC")
    @projects = @category.projects.order("updated_at DESC")

    respond_to do |format|
      format.html
      format.json { render :json => @collections }
    end
  end

  # GET /categories/new
  # GET /categories/new.json
  def new
    @category = Category.new
    respond_to do |format|
      format.html { create }
      format.json { render :json => @collection }
    end
  end

  # GET /categories/1/edit
  def edit
    @category = Category.find(params[:id])
  end

  # DELETE /categories/1
  # DELETE /categories/1.json
  def destroy
    @category = Category.find(params[:id])
    @category.destroy

    respond_to do |format|
      format.html { redirect_to user_path(current_user.username) }
      format.json { head :no_content }
    end
  end
end

