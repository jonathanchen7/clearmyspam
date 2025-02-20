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
      toast.success("#{inbox.size} Emails Loaded")
    end

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(toast: toast)
      end
    end
  end

  def load_more
    if inbox.size > Inbox::INBOX_MAX_SIZE
      render_failure "Inbox is at max capacity.", show_toast: true
      return
    end

    if sender.present?
      if inbox.final_page_fetched?(sender_id: sender.id)
        render_failure "All emails from #{sender.email} have already been fetched.", show_toast: true
        return
      end
    else
      if inbox.final_page_fetched?
        render_failure "All emails have already been fetched.", show_toast: true
        return
      end
    end

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
        toast.success "#{new_emails_count} New Emails Loaded #{sender.present? ? "from #{sender.name}" : nil}"
      else
        toast.info "No New Emails Found #{sender.present? ? "for #{sender.name}" : nil}"
      end

      sync_inbox_metrics!
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
