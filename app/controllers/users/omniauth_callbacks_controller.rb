# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])
    session[:google_access_token] = request.env["omniauth.auth"].credentials.token
    session[:google_access_token_expires_at] = Time.at(request.env["omniauth.auth"].credentials.expires_at)

    sign_in @user, event: :authentication
    redirect_to app_path
  end

  def failure
    redirect_to root_path
  end
end
