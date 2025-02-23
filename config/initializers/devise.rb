# frozen_string_literal: true

Devise.setup do |config|
  require "devise/orm/active_record"

  GOOGLE_OAUTH_SCOPES = %w[
    email
    profile
    gmail.modify
  ].freeze

  config.omniauth :google_oauth2,
                  Rails.application.credentials.dig(:google, :client_id),
                  Rails.application.credentials.dig(:google, :client_secret),
                  scope: GOOGLE_OAUTH_SCOPES.join(", "),
                  prompt: "select_account",
                  image_aspect_ratio: "smart",
                  access_type: "offline"

  config.sign_out_via = :delete
end
