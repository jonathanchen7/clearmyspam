# frozen_string_literal: true

class DashboardController < AuthenticatedController
  include DashboardHelper

  rate_limit to: 20, within: 1.minute, by: -> { current_user.id }

  before_action :set_or_refresh_google_auth, except: [:logout]
  before_action :set_cached_inbox, only: [:load_more]
  before_action :set_sender, if: -> { params[:sender_id].present? }

  after_action -> { inbox.cache! }, only: [:resync, :load_more]

  attr_reader :sender

  def index
  end

  def sync
    with_rate_limit_rescue { set_or_create_inbox }

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(toast: toast)
      end
    end
  end

  def resync
    with_rate_limit_rescue do
      reset_inbox
      toast.success I18n.t("toasts.resync.success.title", count: inbox.size)
    end

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(toast: toast)
      end
    end
  end

  def load_more
    if inbox.size > Inbox::MAX_CAPACITY
      toast.error(
        I18n.t("toasts.load_more.max_capacity.title"),
        text: I18n.t("toasts.load_more.max_capacity.text", dispose: Current.options.archive ? "archive" : "delete")
      )
    elsif sender.present? && inbox.final_page_fetched?(sender_id: sender.id)
      toast.error I18n.t("toasts.load_more.no_more.title", sender: " from #{sender.name}")
    elsif sender.blank? && inbox.final_page_fetched?
      toast.error I18n.t("toasts.load_more.no_more.title", sender: nil)
    else
      with_rate_limit_rescue do
        thread_fetcher = EmailThreadFetcher.new(current_user)
        email_threads, page_token = if sender.present?
                                      thread_fetcher.fetch_threads_from_emails!(
                                        [sender.email],
                                        unread_only: Current.options.unread_only,
                                        sender_page_token: inbox.next_page_token(sender_id: sender.id)
                                      )
                                    else
                                      thread_fetcher.fetch_threads!(
                                        unread_only: Current.options.unread_only,
                                        page_token: inbox.next_page_token
                                      )
                                    end
        set_cached_inbox # Fetch the inbox from the cache again to ensure we have the latest data.
        new_emails_count = inbox.populate(email_threads, page_token: page_token, sender_id: sender&.id)

        if new_emails_count.positive?
          toast.success I18n.t("toasts.load_more.success.title",
                               count: new_emails_count,
                               sender: sender.present? ? " from #{sender.name}" : nil)
        else
          toast.info I18n.t("toasts.load_more.no_more.title", sender: sender.present? ? " from #{sender.name}" : nil)
        end

        sync_inbox_metrics!
      end
    end

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(toast: toast, drawer_options: params[:drawer_options])
      end
    end
  end

  def logout
    Inbox.delete_from_cache!(current_user)
    sign_out(current_user)

    redirect_to root_path
  end

  private

  def set_sender
    @sender ||= inbox.sender_lookup(params[:sender_id].to_i)
  end
end
