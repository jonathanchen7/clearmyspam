Rails.application.routes.draw do
  # Route Omniauth callbacks to the Devise controller.
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  devise_scope :user do
    delete "/users/sign_out" => "devise/sessions#destroy"
  end

  authenticate :user, ->(user) { user.admin? } do
    mount GoodJob::Engine => "good_job"
  end

  # Marketing
  get "f5bot", to: "home#index"
  get "home/index"
  get "faq", to: "faq#index"

  get "pricing", to: "pricing#index"
  namespace :pricing do
    get :index
    post :checkout
    post :billing_portal
  end

  get "/sitemap.xml", to: "sitemap#index", format: "xml"

  # get "blogs/", to: "blogs#index"
  get "blogs/:slug", to: "blogs#show", as: :blogs_show

  get "terms", to: "terms#index"
  get "privacy", to: "privacy#index"

  # Webhooks
  post "webhooks/stripe"

  # Dashboard
  namespace :dashboard do
    get :index
    post :sync
    post :resync
    post :logout
    post :help
  end
  post "load_more(/:sender_id)", to: "dashboard#load_more", controller: "dashboard", as: :dashboard_load_more
  get "app", to: "dashboard#index"

  post "onboarding/step/:step", to: "onboarding#step", as: :onboarding_step
  post "onboarding/complete", to: "onboarding#complete", as: :onboarding_complete

  post "options", to: "options#update", as: :options_update

  namespace :emails do
    post :protect
    post :unprotect
    post :dispose
  end

  namespace :senders do
    post :protect
    post :unprotect
    post :dispose_all
  end

  # Sender actions.
  get "senders/:sender_id", to: "senders#show", as: :senders_show
  get "senders/:sender_id/emails", to: "senders#emails", as: :senders_emails
  post "senders/:sender_id/unsubscribe", to: "senders#unsubscribe", as: :senders_unsubscribe

  root "home#index"
end
