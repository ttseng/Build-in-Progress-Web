class DesignFilesController < ApplicationController

  before_filter :authenticate_user!

  # GET /design_files
  def index
    @designFiles = DesignFile.find(:all)    
  end

  # GET /design_files/1
  def show
    @designFile = DesignFile.find(params[:id])
  end

  # GET /design_files/new
  def new
    @designFile = DesignFile.new
  end

  # POST /design_files
  def create
    if params[:design_file]
      @designFile = DesignFile.create(params[:design_file])
    end
  
    # update the corresponding project
    @designFile.project.touch

    respond_to do |format|
      format.html {render nothing: true}
      format.js
    end
  end

  # DELETE /design_files/1
  def destroy
    @designFile = DesignFile.find(params[:id])    

    if @designFile.user == current_user
      Rails.logger.debug("destroying design file")
      @designFile.destroy
    end

    respond_to do |format|
      format.html {render nothing: true}
      format.js
    end
  end
end
