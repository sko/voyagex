VoyageX::Application.routes.draw do
  devise_for :users, controllers: { registrations: "auth/registrations", sessions: "auth/sessions" }

  mount Resque::Server, at: '/4hfg398dmmnrf/resque', as: :resque_admin
  
  mount Comm::Engine => "/comm" unless Rails.env == 'test'

  get '/upload_comments/:upload_id', to: 'uploads#comments', as: :upload_comments
  put '/upload_comments/:upload_id', to: 'uploads#comments', as: :create_upload_comment
  put '/upload_file', to: 'uploads#create', as: :uploads
  put '/upload_file64', to: 'uploads#create_from_base64', as: :json_uploads

  put '/register', to: 'comm/comm#register', as: :comm_register
  post '/subscribe/:channel', to: 'comm/comm#subscribe', as: :comm_subscribe
  post '/publish/:channel', to: 'comm/comm#publish', as: :comm_publish

  root to: 'sandbox#index'
end
