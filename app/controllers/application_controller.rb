class ApplicationController < ActionController::Base
	include PublicActivity::StoreController
  protect_from_forgery
  before_filter :set_notifications_viewed_at
  before_filter :banned?
  helper_method :projects_search
  helper_method :collections_search
  helper_method :users_search

  before_filter :add_allow_credentials_headers

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to errors_unauthorized_path
  end

  rescue_from OAuth2::Error do |exception|
    if exception.response.status == 401
      session[:user_id] = nil
      session[:access_token] = nil
      redirect_to root_url, alert: "Access token expired, try signing in again."
    end
  end

  def after_sign_in_path_for(resource)
      flash.keep(:notice)
      sign_up_url = root_url.sub(/\/$/, '') + new_user_registration_path
      sign_in_url = root_url.sub(/\/$/, '') + new_user_session_path
      forgot_password_url = root_url.sub(/\/$/, '') + new_user_password_path
      new_password_url = root_url.sub(/\/$/, '') + user_password_path
      omni_auth_url = root_url.sub(/\/$/, '') + user_omniauth_authorize_path(:village)      
      
      if (request.referer == sign_in_url) || (request.referer == sign_up_url) || (request.env["omniauth.origin"] ) || (request.referer == forgot_password_url) || (request.referer.include? new_password_url)
        root_path
      else
        stored_location_for(resource) || request.referer || root_path
      end
  end

   def set_notifications_viewed_at
    if current_user
      # update notification seen date if user clicks on notification link
      if !params[:notification_id].blank? && PublicActivity::Activity.where(:id=>params[:notification_id]).present?
        PublicActivity::Activity.find(params[:notification_id]).update_attributes(:viewed=>true)
      end
    end
  end

  def oauth_client
    @oauth_client ||= OAuth2::Client.new(ENV["OAUTH_LOCAL_ID"], ENV["OAUTH_LOCAL_SECRET"], site: ENV["OAUTH_VILLAGE_SERVER"])
  end

  def access_token
    if session[:access_token]
      current_user.update_attributes(:access_token => session[:access_token])
      @access_token ||= OAuth2::AccessToken.new(oauth_client, session[:access_token])
    elsif current_user.access_token.present?
      @access_token ||= OAuth2::AccessToken.new(oauth_client, current_user.access_token)
    end
  end

  def search
    search_term = params[:search]
    search_object = params[:search_object]
    search_category = params[:category] # project categories
    search_type = params[:type] # project / collection type

    projects, projects_text = projects_search(search_term)
    collections, collections_text = collections_search(search_term)
    users, users_text = users_search(search_term)

    if search_object.blank?
      if projects.count > 0
        redirect_to search_projects_path(:search => search_term, :search_results => projects, :search_text => projects_text, :project_count => projects.count, :collection_count => collections.count, :user_count => users.count)
      else
        if collections.count > 0
          redirect_to search_collections_path(:search => search_term, :search_results => collections, :search_text => collections_text, :project_count => projects.count, :collection_count => collections.count, :user_count => users.count)
        else
          if users.count > 0
            redirect_to search_users_path(:search => search_term, :search_results => users, :search_text => users_text, :project_count => projects.count, :collection_count => collections.count, :user_count => users.count)
          else
            redirect_to search_projects_path(:search => search_term, :search_results => projects, :search_text => projects_text, :project_count => projects.count, :collection_count => collections.count, :user_count => users.count)
          end
        end
      end
    else
      if search_object == "project"
        redirect_to search_projects_path(:search => search_term, :search_results => projects, :search_text => projects_text, :category => search_category, :type => search_type, :project_count => projects.count, :collection_count => collections.count, :user_count => users.count)
      elsif search_object == "collection"
        redirect_to search_collections_path(:search => search_term, :search_results => collections, :search_text => collections_text, :type => search_type, :project_count => projects.count, :collection_count => collections.count, :user_count => users.count)
      else
        redirect_to search_users_path(:search => search_term, :search_results => users, :search_text => users_text, :project_count => projects.count, :collection_count => collections.count, :user_count => users.count)
      end
    end
  end

  def projects_search(search_term)
    search_string = '%' + search_term + '%'
    projects = Project.public_projects.where("title ILIKE ? ", search_string).order("updated_at DESC").page(params[:projects_page]).per_page(9)

    logger.debug("IN PROJECTS SEARCH with projects.count #{projects.count}")

    projects_text = Hash.new

    projects.each do |project|
      projects_text[project.id] = project.description
    end

    search = Sunspot.search(Project) do 
      fulltext search_term do
        highlight :description
      end
    end
    projects2 = search.results

    logger.debug("number of search results: #{projects2.length}")

    projects2.each do |project|
      unless projects.include?(project) 
        if project.public?
          logger.debug("adding public project #{project.id}")
          projects = projects << project
        end
      end
    end

    step_search = Sunspot.search(Step) do 
      fulltext search_term do
        highlight :description
      end
    end
    steps = step_search.results

    steps.each do |step|
      unless projects.include?(step.project)
        if step.project.privacy == "public"
          projects = projects << step.project
        end
      end
    end    

    search.hits.each do |hit|
      projects_text[hit.primary_key.to_i] = hit.highlights(:description)[0].format { |word| "<b>#{word}</b>" }
    end

    step_search.hits.each do |hit|
      unless Step.where(:id=>hit.primary_key.to_i).first.project == nil
        proj_id = Step.where(:id=>hit.primary_key.to_i).first.project.id
        projects_text[proj_id] = hit.highlights(:description)[0].format { |word| "<b>#{word}</b>" }
      end
    end

    projects = projects.compact
    
    return [projects, projects_text]
  end

  def collections_search(search_term)
    search_string = '%' + search_term + '%'
    collections = Collection.published.where("name ILIKE ?", search_string).order("updated_at DESC")
    
    collections_text = Hash.new

    collections.each do |collection|
      collections_text[collection.id] = collection.description
    end

    search = Sunspot.search(Collection) do 
      fulltext search_term do
        highlight :description
      end
    end
    collections2 = search.results

    collections2.each do |collection|
      unless collections.include?(collection)
        collections = collections << collection
      end
    end

    search.hits.each do |hit|
      collections_text[hit.primary_key.to_i] = hit.highlights(:description)[0].format { |word| "<b>#{word}</b>" }
    end

    collections = collections.compact

    return collections, collections_text
  end
  
  def users_search(search_term)
    search_string = '%' + search_term + '%'
    users = User.where("username ILIKE ?", search_string).order("updated_at DESC").page(params[:page]).per_page(9)

    users_text = Hash.new

    users.each do |user|
      users_text[user.id] = user.about_me
    end

      search = Sunspot.search(User) do 
        fulltext search_term do
          highlight :about_me
        end
      end
      users2 = search.results

      users2.each do |user|
        unless users.include?(user)
          users = users << user
        end
      end

      search.hits.each do |hit|
        users_text[hit.primary_key.to_i] = hit.highlights(:about_me)[0].format { |word| "<b>#{word}</b>" }
      end

      users = users.compact

      return users, users_text
  end

  def add_allow_credentials_headers                                                                                                                                                                                                                                                        
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS#section_5                                                                                                                                                                                                      
    #                                                                                                                                                                                                                                                                                       
    # Because we want our front-end to send cookies to allow the API to be authenticated                                                                                                                                                                                                   
    # (using 'withCredentials' in the XMLHttpRequest), we need to add some headers so                                                                                                                                                                                                      
    # the browser will not reject the response                                                                                                                                                                                                                                             
    response.headers['Access-Control-Allow-Origin'] = request.headers['Origin'] || '*'                                                                                                                                                                                                     
    response.headers['Access-Control-Allow-Credentials'] = 'true'                                                                                                                                                                                                                          
  end 

  def banned?
    if current_user.present? && current_user.banned?
      sign_out_current_user
      flash[:error] = "Your account has been suspended due to inappropriate use."
      root_path
    end
  end

end


