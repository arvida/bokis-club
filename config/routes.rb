Rails.application.routes.draw do
  # Passwordless authentication
  passwordless_for :users, at: "/", as: :auth

  # Named routes for Swedish URLs
  get "logga-in", to: "passwordless/sessions#new", as: :login
  delete "logga-ut", to: "passwordless/sessions#destroy", as: :logout
  get "registrera", to: "registrations#new", as: :signup
  post "registrera", to: "registrations#create"

  # Dashboard and profile
  get "mina-klubbar", to: "home#dashboard", as: :dashboard
  resource :profile, only: [ :show, :update ], path: "profil"

  # Clubs
  resources :clubs, path: "klubbar", only: [ :new, :create, :show, :edit, :update, :destroy ] do
    resources :members, only: [ :index, :destroy ], path: "medlemmar" do
      patch :promote, on: :member
    end
    post "join", on: :member, to: "clubs#join"
    delete "leave", on: :member, to: "clubs#leave"
    patch "regenerate_invite", on: :member, to: "clubs#regenerate_invite"
  end

  # Invites
  get "bjud-in/:code", to: "invites#show", as: :invite
  post "bjud-in/:code", to: "invites#create"

  # Root redirects to login or dashboard based on auth state
  root to: redirect("/logga-in")

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
