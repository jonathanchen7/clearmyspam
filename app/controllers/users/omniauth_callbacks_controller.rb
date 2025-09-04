# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])
    session[:google_access_token] = request.env["omniauth.auth"].credentials.token
    session[:google_access_token_expires_at] = Time.at(request.env["omniauth.auth"].credentials.expires_at)

    sign_in @user, event: :authentication

    if @user.brand_new?
      pixel_client = Facebook::PixelClient.from_request(current_user, request)
      pixel_client.track_event(Facebook::EventType::StartTrial)
    end

    redirect_to app_path
  end

  def failure
    redirect_to root_path
  end
end
