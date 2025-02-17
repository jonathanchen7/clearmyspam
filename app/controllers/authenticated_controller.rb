# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_options
  before_action :configure_header

  private

  attr_reader :inbox

  def reset_inbox
    Inbox.delete_from_cache!(current_user)
    @inbox = new_inbox
  end

  def set_or_create_inbox
    @inbox = Inbox.fetch_from_cache(current_user) { new_inbox }
  end

  def set_cached_inbox
    cached_inbox = Inbox.fetch_from_cache(current_user)
    if cached_inbox.blank?
      raise ArgumentError, "Could not find cached inbox."
    else
      @inbox = cached_inbox
    end
  end

  def new_inbox
    inbox = Inbox.new(current_user.id)

    begin
      thread_fetcher = EmailThreadFetcher.new(current_user)
      email_threads, next_page_token = thread_fetcher.fetch_threads!(unread_only: Current.options.unread_only)
      inbox.populate(email_threads, page_token: next_page_token)
    rescue Google::Apis::RateLimitError
      flash.alert = "Gmail rate limit exceeded. Please wait 10 seconds and try again."
    end

    inbox
  end

  def sync_inbox_metrics!(internal_only: false)
    internal_only ? inbox.metrics.sync_internal!(current_user) : inbox.metrics.sync!(current_user)
  end

  def render_failure(error, toast: false)
    error_message = error.try(:message) || error
    respond_to do |format|
      format.json { render json: { success: false, error: error_message }, status: :bad_request }
      format.turbo_stream do
        render turbo_stream: [render_toast(title: "Error", text: error_message, type: ToastComponent::TYPE::ERROR)] if toast
      end
    end
  end

  def render_toast(title:, text: nil, type: ToastComponent::TYPE::INFO, icon: nil, cta_text: nil, cta_stimulus_data: nil)
    turbo_stream.prepend("notifications", ToastComponent.new(
      title: title,
      text: text,
      type: type,
      icon: icon,
      cta_text: cta_text,
      cta_stimulus_data: cta_stimulus_data
    ))
  end

  def set_or_refresh_google_auth
    current_user.update(
      google_access_token: session[:google_access_token],
      google_access_token_expires_at: session[:google_access_token_expires_at]
    )

    current_user.refresh_google_auth!(session: session) if current_user.google_auth_expired?
  end

  def set_current_options
    Current.options = Option.find_or_create_by(user_id: current_user.id)
  end

  def configure_header
    @hide_header_navigation = true
  end
end
