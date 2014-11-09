VoyageX::Application.routes.draw do
  mount Resque::Server, at: '/4hfg398dmmnrf/resque', as: :resque_admin
  
  mount Comm::Engine => "/comm"

  root to: 'sandbox#index'
end
