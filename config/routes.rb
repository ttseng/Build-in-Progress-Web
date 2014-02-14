require 'sidekiq/web'

Build::Application.routes.draw do

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

  devise_for :users, :controllers => {:registrations => :registrations}

  devise_scope :user do
      post 'registrations' => 'registrations#create', :as => 'register'
      post 'sessions' => 'sessions#create', :as => 'login'
      delete 'sessions' => 'sessions#destroy', :as => 'logout'
    end

  get "home/index"
  get "about", to: "home#about"
  get "help", to: "home#help"
  get "news", to: "home#news"
  get "android", to: "home#android"

  match 'contact' => 'contact#new', :as=> 'contact', :via => :get
  match 'contact' => 'contact#create', :as=> 'contact', :via=>:post
  match 'announcements/:id/hide', to: 'home#hide_announcement', as: 'hide_announcement'

  resources :users do
     match 'users/:id' => 'users#username'
     get 'validate_username', on: :collection
     get 'validate_email', on: :collection
     get 'edit_profile', on: :member
     get :projects, on: :member
     get :favorites, on: :member
     get :collections, on: :member
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
     get :editTitle, on: :collection
     post :categorize, on: :member
     put :favorite, on: :member
     put :remix, on: :member
     get :embed, on: :member
     get :find_users, on: :collection
     get :add_users, on: :collection
     get :remove_user, on: :collection
    resources :steps do
        collection {post :sort}
        resources :comments, :only => [:create, :destroy]
        get :create_branch, on: :collection
        get :reset_started_editing, on: :member
        get :update_ancestry, on: :collection
        get :edit_redirect, on: :collection
        get :show_redirect, on: :collection
        get :update_new_image, on: :member
      end
      match "steps/:id" => "steps#number", :as => :number
  end

  resources :images do
     collection {post :sort}
  end

  mount Sidekiq::Web, at: "/sidekiq"

  get "videos/embed_url" => "videos#embed_url", :as => :video_embed_url
  
  resources :videos do
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

