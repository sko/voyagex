VoyageX::Application.routes.draw do
  devise_for :users, controllers: { registrations: "auth/registrations", sessions: "auth/sessions" }

  mount Resque::Server, at: '/4hfg398dmmnrf/resque', as: :resque_admin
  
  mount Comm::Engine => "/comm" unless Rails.env == 'test'

  put 'upload_photo', to: 'uploads#create', as: :uploads

  root to: 'sandbox#index'
end
