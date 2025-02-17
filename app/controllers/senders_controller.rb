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
      format.json { render json: { success: true } }
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("inbox", partial: "dashboard/sender_drawer", locals: { sender: sender })
      end
    end
  end

  def unsubscribe
    url = UnsubscribeLinkFinder.find_link!(current_user, inbox.sender_emails(sender.id).first)

    if url.blank?
      render_failure("We couldn't find a link to unsubscribe from #{sender.email}.", toast: true)
    else
      render json: { success: true, url: url }
    end
  end

  private

  def set_sender
    sender_id = params.require(:sender_id)
    @sender = inbox.sender_lookup(sender_id)

    render json: { success: false, error: "Invalid sender." }, status: :not_found if sender.blank?
  end
end
