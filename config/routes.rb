Rails.application.routes.draw do
  # Passwordless authentication
  passwordless_for :users, at: "/", as: :auth

  # Authentication routes
  get "login", to: "passwordless/sessions#new", as: :login
  delete "logout", to: "passwordless/sessions#destroy", as: :logout
  get "signup", to: "registrations#new", as: :signup
  post "signup", to: "registrations#create"

  # Dashboard and profile
  get "dashboard", to: "home#dashboard", as: :dashboard
  resource :profile, only: [ :show, :update ]

  # Books
  resources :books, only: [] do
    collection do
      get :search
    end
  end

  # Clubs
  resources :clubs, only: [ :new, :create, :show, :edit, :update, :destroy ] do
    resources :members, only: [ :index, :destroy ] do
      patch :promote, on: :member
    end
    resources :club_books, path: "books", only: [ :index, :show, :new, :create, :destroy ] do
      member do
        patch :set_reading
      end
      collection do
        get :suggest
        post :suggest
        post :start_voting
        get :vote
        post :vote
        post :end_voting
        post :start_next_book
        delete :cancel_next_book
        post :mark_complete
        get :archive
      end
    end
    post "join", on: :member, to: "clubs#join"
    delete "leave", on: :member, to: "clubs#leave"
    patch "regenerate_invite", on: :member, to: "clubs#regenerate_invite"
  end

  # Invites
  get "invite/:code", to: "invites#show", as: :invite
  post "invite/:code", to: "invites#create"

  # Root redirects to login or dashboard based on auth state
  root to: redirect("/login")

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
