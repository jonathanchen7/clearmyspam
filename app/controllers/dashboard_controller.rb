# frozen_string_literal: true

class DashboardController < AuthenticatedController
  rate_limit to: 20, within: 1.minute, by: -> { current_user.id }

  before_action :set_or_refresh_google_auth, except: [:logout]
  before_action :set_or_create_inbox, only: [:sync]
  before_action :set_cached_inbox, only: [:load_more]
  before_action :set_sender, if: -> { params[:sender_id].present? }

  after_action -> { inbox.cache! }, only: [:resync, :load_more]

  attr_reader :sender

  def index
  end

  def sync
    sync_inbox_metrics!

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("senders_table", partial: "dashboard/senders_table"),
          turbo_stream.replace("toolbar", partial: "dashboard/toolbar")
        ]
      end
    end
  end

  def resync
    reset_inbox
    sync_inbox_metrics!

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("senders_table", partial: "dashboard/senders_table"),
          turbo_stream.replace("toolbar", partial: "dashboard/toolbar"),
          render_toast(type: ToastComponent::TYPE::SUCCESS, title: "#{inbox.size} Emails Loaded")
        ]
      end
    end
  end

  def load_more
    if inbox.size > Inbox::INBOX_MAX_SIZE
      render_failure "Inbox is at max capacity.", toast: true
      return
    end

    if sender.present?
      if inbox.final_page_fetched?(sender_id: sender.id)
        render_failure "All emails from #{sender.email} have already been fetched.", toast: true
        return
      end
    else
      if inbox.final_page_fetched?
        render_failure "All emails have already been fetched.", toast: true
        return
      end
    end

    begin
      thread_fetcher = EmailThreadFetcher.new(current_user)
      email_threads, page_token = if sender.present?
                                    thread_fetcher.fetch_threads_from_email!(
                                      sender.email,
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

      sync_inbox_metrics!
    rescue Google::Apis::RateLimitError
      flash.alert = "Gmail rate limit exceeded. Please wait 10 seconds and try again."
    end

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream do
        turbo_streams = [
          turbo_stream.replace("senders_table", partial: "dashboard/senders_table"),
          turbo_stream.replace("toolbar", partial: "dashboard/toolbar")
        ]

        toast_title = if new_emails_count.positive?
                        "#{new_emails_count} New Emails Loaded #{sender.present? ? "from #{sender.name}" : nil}"
                      else
                        "No New Emails Found #{sender.present? ? "for #{sender.name}" : nil}"
                      end
        turbo_streams << render_toast(
          type: new_emails_count.positive? ? ToastComponent::TYPE::SUCCESS : ToastComponent::TYPE::INFO,
          title: toast_title
        )

        if params[:drawer].present? && sender.present?
          turbo_streams << turbo_stream.replace("sender_drawer", partial: "dashboard/sender_drawer", locals: { sender: sender })
        end
        render turbo_stream: turbo_streams
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
