VoyageX::Application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: 'auth/omniauth_callbacks',
                            registrations: "auth/registrations",
                            sessions: "auth/sessions" }
  devise_scope :user do
    match '/auth/:provider', to: 'sessions#create', via: [:get, :post], as: :authentication
    match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post], as: :authentication_callback
    match '/auth/failure', to: 'sessions#failure', via: [:get, :post]
    match '/auth/facebook/disconnect', to: 'users#disconnect_from_facebook', via: [:get, :post]
    match '/auth/twitter/disconnect', to: 'users#disconnect_from_twitter', via: [:get, :post]
  end

  mount Resque::Server, at: '/4hfg398dmmnrf/resque', as: :resque_admin
  
  mount Comm::Engine => "/comm" unless Rails.env == 'test'

  resources :users, only: [:update] do
  end
  get '/peers/:location_id', to: 'users#peers', as: :peers
 #get '/peers/:lat/:lng', to: 'users#peers', as: :peers, :constraints => { :lat => /([0-9]+\.[0-9]+|:[a-z]+)/,
 #                                                                         :lng => /([0-9]+\.[0-9]+|:[a-z]+)/ }

  get '/location_bookmarks', to: 'main#index'
#  get '/location/:location_id', to: 'main#location', as: :location
  get '/location_data/:location_id', to: 'main#location_data', as: :location_data
  get '/pois/:lat/:lng', to: 'uploads#pois', as: :pois, :constraints => { :lat => /([0-9]+\.[0-9]+|:[a-z]+)/,
                                                                          :lng => /([0-9]+\.[0-9]+|:[a-z]+)/ }

  resources :uploads, only: [:index, :create, :update, :destroy] do
  end
  post '/uploads_base64', to: 'uploads#create_from_base64', as: :uploads_base64
  put '/upload_base64/:id', to: 'uploads#update_from_base64', as: :upload_base64
  post '/uploads_embed', to: 'uploads#create_from_embed', as: :uploads_embed
  put '/uploads_embed/:id', to: 'uploads#update_from_embed', as: :upload_embed
  post '/uploads_plain_text', to: 'uploads#create_from_plain_text', as: :uploads_plain_text
  put '/uploads_plain_text/:id', to: 'uploads#update_from_plain_text', as: :upload_plain_text
  post '/sync_pois', to: 'uploads#sync_poi', as: :sync_pois
  put '/sync_poi/:id', to: 'uploads#sync_poi', as: :sync_poi
  post '/uploads', to: 'uploads#create', as: :poi_notes
  put '/uploads/:id', to: 'uploads#update', as: :poi_note

  get '/manifest', to: 'main#manifest', as: :manifest
#  get '/context_nav/:lat/:lng', to: 'main#context_nav', as: :context_nav, :constraints => { :lat => /([0-9]+\.[0-9]+|:[a-z]+)/,
#                                                                                         :lng => /([0-9]+\.[0-9]+|:[a-z]+)/ }
  match '/change_username', to: 'users#change_details', as: :change_username, via: [:get, :post]
  match '/set_user_detail/:detail', to: 'users#change_details', as: :set_user_detail, via: [:get, :post]
  get '/csrf', to: 'uploads#csrf', as: :csrf
  get '/upload_comments/:poi_id/:poi_note_id', to: 'uploads#comments', as: :upload_comments
  #put '/upload_comments/:upload_id', to: 'uploads#comments', as: :create_upload_comment
  #put '/upload_file', to: 'uploads#create'
  #post '/upload_file', to: 'uploads#update'
  #put '/upload_file64', to: 'uploads#create_from_base64', as: :json_uploads
  get '/ping/:key', to: 'comm/comm#ping', as: :comm_ping
  put '/register', to: 'comm/comm#register', as: :comm_register
  #post '/subscribe/:channel', to: 'comm/comm#subscribe', as: :comm_subscribe
  #post '/publish/:channel', to: 'comm/comm#publish', as: :comm_publish

  get '/test/javascript', to: 'test#javascript', as: :test_javascript

  get '/thesis', to: 'thesis#index', as: :thesis
  
  root to: 'main#index'
end
