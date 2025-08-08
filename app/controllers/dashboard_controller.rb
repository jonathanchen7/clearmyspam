# frozen_string_literal: true

class DashboardController < AuthenticatedController
  include DashboardHelper
  include VerbTenseHelper

  set_rate_limit to: 20

  before_action :set_or_refresh_google_auth, except: [:index, :logout]
  before_action :set_cached_inbox, only: [:load_more]

  after_action -> { inbox.cache! }, only: [:resync, :load_more]

  attr_reader :sender

  def index
  end

  def sync
    set_or_create_inbox

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(toast: toast)
      end
    end
  end

  def resync
    reset_inbox
    toast.success I18n.t("toasts.resync.success.title", count: inbox.email_count)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(toast: toast)
      end
    end
  end

  def load_more
    if inbox.sender_count > Inbox::MAX_SENDERS
      toast.error(
        I18n.t("toasts.load_more.max_capacity.title"),
        text: I18n.t("toasts.load_more.max_capacity.text", dispose: dispose_verb)
      )
    elsif inbox.final_page_fetched?
      toast.error I18n.t("toasts.load_more.no_more.title")
    else
      senders, next_page_token = Gmail::Client.new(current_user).get_unique_senders!(
        max_results: Rails.configuration.sync_fetch_count,
        page_token: inbox.page_tokens.next
      )

      inbox.populate(senders, page_token: next_page_token)
      sync_inbox_metrics!

      toast.success I18n.t("toasts.load_more.success.title", count: senders.size)
    end

    render turbo_stream: build_turbo_stream(toast: toast)
  end

  def help
    @show_onboarding_wizard = true

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("onboarding", partial: "onboarding")
      end
    end
  end

  def logout
    logout!
  end

  private

  def set_sender
    @sender ||= inbox.sender_lookup(params[:sender_id].to_i)
  end
end
