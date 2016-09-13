Build::Application.routes.draw do

  devise_for :admins

  if Rails.env.development?
    mount MailPreview => 'mail_view'
  end

  get "search/new"

  get "errors/not_found"

  get "errors/unacceptable"

  get "errors/internal_error"

  get "errors/unauthorized"

  resources :notifications do
    collection {post :sort}
    get :update_seen, on: :collection
  end

  resources :activity_feed do
    collection {post :sort}
  end

  devise_for :users, :controllers => {:registrations => :registrations, omniauth_callbacks: "users/omniauth_callbacks"} 

  devise_scope :user do
      post 'registrations' => 'registrations#create', :as => 'register'
      post 'sessions' => 'sessions#create', :as => 'login'
      delete 'sessions' => 'sessions#destroy', :as => 'logout'
  end

  get "home/index"
  get "about", to: "home#about"
  get "help", to: "home#help"
  get "documentation_tips", to: "home#documentation_tips"
  get "news", to: "home#news"
  get "mobile", to: "home#mobile"
  get "mobile/request", to: "home#mobile_request"
  get "privacy_policy", to: "home#privacy_policy"
  get "dashboard", to: "home#dashboard"

  match 'contact' => 'contact#new', :as=> 'contact', :via => :get
  match 'contact' => 'contact#create', :as=> 'contact', :via=>:post
  match 'announcements/:id/hide', to: 'home#hide_announcement', as: 'hide_announcement'
  match 'search', to: 'application#search', as: :search

  resources :users, :id => /[A-Za-z0-9\-\_\.\+]+?/ , :format => /json|csv|xml|yaml/ do
     match 'users/:id' => 'users#username'
     get 'validate_username', on: :collection
     get 'validate_email', on: :collection
     get :search, on: :collection
     get 'edit_profile', on: :member
     get :projects, on: :member
     get :favorites, on: :member
     get :collections, on: :member
     get :touch, on: :collection
     member do
      get :follow
      get :unfollow
      get :following
      get :followers
     end
  end

  resources :collections do
    post :add_project, on: :member
    get :projects, on: :member
    get :challenges, on: :collection
    get :search, on: :collection
    get :update_privacy, on: :member
  end

  resources :collectifies do
  end

  resources :categories do
  end

  resources :projects do
     collection {post :sort}
     get :builds, on: :collection
     get :built, on: :collection
     get :featured, on: :collection
     get :search, on: :collection
     get :editTitle, on: :collection
     post :categorize, on: :member
     put :favorite, on: :member
     put :remix, on: :member
     get :embed, on: :member
     get :gallery, on: :member
     get :imageView, on: :member
     get :blog, on: :member
     get :export, on: :member
     get :export_txt, on: :member
     get :update_privacy, on: :member
     get :find_users, on: :collection
     get :add_users, on: :collection
     get :remove_user, on: :collection
     get :check_privacy, on: :collection
     get :log, on: :member
     get :timemachine, on: :member
    resources :steps do
        collection {post :sort}
        resources :comments, :only => [:create, :destroy]
        get :create_branch, on: :collection
        get :reset_started_editing, on: :member
        get :update_ancestry, on: :collection
        get :edit_redirect, on: :collection
        get :get_position, on: :collection
        get :show_redirect, on: :collection
        get :update_new_image, on: :member
        get :mobile, on: :collection
      end
      match "steps/:id" => "steps#number", :as => :number
  end

  resources :images do
     collection {post :sort}
     get :find_image_id, on: :collection
     get :rotate, on: :member
     get :export, on: :member
  end

  resources :charts do
    get :users, on: :collection
    get :users_by_month, on: :collection
    get :steps, on: :collection
    get :steps_by_month, on: :collection
    get :comments, on: :collection
    get :comments_by_month, on: :collection
  end

  get "videos/embed_url" => "videos#embed_url", :as => :video_embed_url
  
  resources :videos do
    post :create_mobile, on: :collection
  end

  resources :sounds do
  end
      
  resources :design_files do
  end

  root :to => 'home#index'

  post "versions/:id/revert" => "versions#revert", :as => "revert_version"

  %w( 404 422 500 ).each do |code|
    get code, :to => "errors#show", :code => code
  end

end


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action


  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.


  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

