# frozen_string_literal: true

class SendersController < AuthenticatedController
  rate_limit to: 30, within: 1.minute, only: [:show], by: -> { current_user.id }
  rate_limit to: 10, within: 1.minute, only: [:unsubscribe], by: -> { current_user.id }

  before_action :set_cached_inbox
  before_action :set_sender
  before_action :set_or_refresh_google_auth, only: [:unsubscribe]

  attr_reader :sender, :inbox

  def show
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("inbox",
                                                 partial: "dashboard/sender_drawer",
                                                 locals: { sender: sender })
      end
    end
  end

  def unsubscribe
    sender_emails = inbox.sender_emails(sender.id)

    url = nil
    sender_emails.first(3).each do |email|
      url = UnsubscribeLinkFinder.find_link!(current_user, email)
      break if url.present?
    end

    render json: { success: true, url: url }
  end

  private

  def set_sender
    sender_id = params.require(:sender_id)
    @sender = inbox.sender_lookup(sender_id)

    raise "sender could not be found" if sender.blank?
  end
end
