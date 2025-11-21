Rails.application.routes.draw do
  # Route Omniauth callbacks to the Devise controller.
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  devise_scope :user do
    delete "/users/sign_out" => "devise/sessions#destroy"
  end

  authenticate :user, ->(user) { user.admin? } do
    mount GoodJob::Engine => "good_job"
    get "admin", to: "admin#index"
    post "admin/trigger_re_engagement", to: "admin#trigger_re_engagement", as: :admin_trigger_re_engagement
  end

  get "home/index"
  get "faq", to: "faq#index"
  get "start", to: "start#index"

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

  namespace :marketing do
    match "unsubscribe", to: "unsubscribe#index", via: [:get, :post]
  end

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
    post :move_all
  end

  # Labels modal
  get "senders/labels_modal", to: "senders#labels_modal", as: :senders_labels_modal

  # Sender actions.
  get "senders/:sender_id", to: "senders#show", as: :senders_show
  get "senders/:sender_id/emails", to: "senders#emails", as: :senders_emails
  get "senders/:sender_id/preview/:email_id", to: "senders#preview", as: :senders_preview
  post "senders/:sender_id/unsubscribe", to: "senders#unsubscribe", as: :senders_unsubscribe

  root "home#index"
end
