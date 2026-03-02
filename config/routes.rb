Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Public
  root "home#index"
  get  "help_requests/new", to: "help_requests#new", as: :new_help_request
  post "help_requests",     to: "help_requests#create"

  # NGO session
  get    "ngo/login",   to: "sessions#new",    as: :ngo_login
  post   "ngo/session", to: "sessions#create", as: :ngo_session
  delete "ngo/session", to: "sessions#destroy", as: :ngo_logout

  # NGO area (authenticated)
  namespace :ngo do
    get "help_requests", to: "help_requests#index", as: :help_requests
    get "help_requests/export", to: "help_requests#export", as: :export_help_requests, defaults: { format: :csv }
    get "help_requests/completed", to: "help_requests#completed", as: :completed_help_requests
    delete "help_requests/:id", to: "help_requests#destroy", as: :help_request
    patch "help_requests/:id", to: "help_requests#update", as: :help_request_update
    patch "help_requests/:id/observation", to: "help_requests#update_observation", as: :help_request_observation
    delete "help_requests/:id/observation", to: "help_requests#clear_observation", as: :clear_help_request_observation
  end
end
