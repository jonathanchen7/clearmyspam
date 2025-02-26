# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  rescue_from Google::Apis::AuthorizationError,
              Google::Apis::ClientError,
              User::GoogleRefreshTokenMissingError,
              with: ->(error) { handle_google_authorization_error(error) }

  rescue_from Signet::AuthorizationError, with: :logout!

  rescue_from Inbox::CachingError, with: :handle_inbox_cache_error

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
      raise Inbox::CachingError, "Could not find cached inbox."
    else
      @inbox = cached_inbox
    end
  end

  def new_inbox
    inbox = Inbox.new(current_user.id)

    thread_fetcher = EmailThreadFetcher.new(current_user)
    email_threads, next_page_token = thread_fetcher.fetch_threads!(unread_only: Current.options.unread_only)
    inbox.populate(email_threads, page_token: next_page_token)
    inbox.metrics.sync!(current_user)

    inbox
  end

  def sync_inbox_metrics!(internal_only: false)
    internal_only ? inbox.metrics.sync_internal!(current_user) : inbox.metrics.sync!(current_user)
  end

  def with_rate_limit_rescue
    yield
  rescue Google::Apis::RateLimitError
    @inbox = Inbox.new(current_user) if inbox.nil?
    toast.error I18n.t("toasts.gmail_rate_limit.title"), text: I18n.t("toasts.gmail_rate_limit.text")
  end

  def render_failure(error, show_toast: false)
    error_message = error.try(:message) || error
    respond_to do |format|
      format.json { render json: { success: false, error: error_message }, status: :bad_request }
      format.turbo_stream do
        render turbo_stream: [toast.error("Error", text: error_message)] if show_toast
      end
    end
  end

  def set_or_refresh_google_auth
    raise User::GoogleRefreshTokenMissingError if current_user.google_refresh_token.blank?

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

  def handle_google_authorization_error(error)
    raise error if error.is_a?(Google::Apis::ClientError) && error.message.exclude?("PERMISSION_DENIED")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("senders_table", partial: "dashboard/invalid_permissions")
      end
    end
  end

  def handle_inbox_cache_error
    toast.error(
      "Error",
      text: "Sorry, something went wrong. Try refreshing the page or waiting a few seconds between each action."
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.prepend("notifications", toast)
      end
    end
  end

  def logout!
    Inbox.delete_from_cache!(current_user)
    sign_out(current_user)

    redirect_to root_url
  end
end
