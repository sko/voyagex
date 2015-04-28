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
  get '/pois/:lat/:lng', to: 'pois#pois', as: :pois, :constraints => { :lat => /([0-9]+\.[0-9]+|:[a-z]+)/,
                                                                          :lng => /([0-9]+\.[0-9]+|:[a-z]+)/ }
  #resources :pois, only: [:index, :create, :update, :destroy] do
  #end
  post '/pois_base64', to: 'pois#create_from_base64', as: :pois_base64
  put '/poi_base64/:id', to: 'pois#update_from_base64', as: :poi_base64
  post '/pois_embed', to: 'pois#create_from_embed', as: :pois_embed
  put '/pois_embed/:id', to: 'pois#update_from_embed', as: :poi_embed
  post '/pois_plain_text', to: 'pois#create_from_plain_text', as: :pois_plain_text
  put '/pois_plain_text/:id', to: 'pois#update_from_plain_text', as: :poi_plain_text
  post '/sync_pois', to: 'pois#sync_poi', as: :sync_pois
  put '/sync_poi/:id', to: 'pois#sync_poi', as: :sync_poi
  post '/pois', to: 'pois#create', as: :poi_notes
  put '/pois/:id', to: 'pois#update', as: :poi_note
  delete '/pois/:id', to: 'pois#destroy'

  get '/manifest', to: 'main#manifest', as: :manifest
  match '/set_user_detail/:detail', to: 'users#change_details', as: :set_user_detail, via: [:get, :post]
  delete '/set_user_detail/:detail', to: 'users#delete_details'
  get '/csrf', to: 'pois#csrf', as: :csrf
  get '/poi_comments/:poi_id/:poi_note_id', to: 'pois#comments', as: :poi_comments
  #put '/poi_comments/:poi_id', to: 'pois#comments', as: :create_poi_comment
  #put '/poi_file', to: 'pois#create'
  #post '/poi_file', to: 'pois#update'
  #put '/poi_file64', to: 'pois#create_from_base64', as: :json_pois
  get '/ping/:key', to: 'comm/comm#ping', as: :comm_ping
  put '/register', to: 'comm/comm#register', as: :comm_register
  #post '/subscribe/:channel', to: 'comm/comm#subscribe', as: :comm_subscribe
  #post '/publish/:channel', to: 'comm/comm#publish', as: :comm_publish

  get '/test/javascript', to: 'test#javascript', as: :test_javascript

  get '/thesis', to: 'thesis#index', as: :thesis
  
  root to: 'main#index'
end
