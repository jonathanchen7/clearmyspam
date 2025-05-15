# frozen_string_literal: true

class SendersController < AuthenticatedController
  rate_limit to: 30, within: 1.minute, only: [:show], by: -> { current_user.id }
  rate_limit to: 10, within: 1.minute, only: [:unsubscribe], by: -> { current_user.id }

  before_action :set_cached_inbox
  before_action :set_sender
  before_action :set_emails, only: [:show, :update_page]
  before_action :set_or_refresh_google_auth, only: [:unsubscribe]

  after_action -> { inbox.cache! }, only: [:show, :update_page]

  attr_reader :sender, :inbox, :emails

  def show
    sender.get_email_count!(current_user)

    render turbo_stream: turbo_stream.append("inbox", partial: "dashboard/sender_drawer", locals: { sender:, emails: })
  end

  def update_page
    render turbo_stream: turbo_stream.replace(
      "sender_drawer",
      partial: "dashboard/sender_drawer",
      locals: { sender:, emails:, page: params[:page] }
    )
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

  def set_emails
    page = params[:page] || 1
    page_token = page == 1 ? nil : inbox.page_tokens.for(page: page - 1, sender_id: sender.id)

    emails, next_page_token = sender.get_emails!(current_user, page_token: page_token)
    inbox.page_tokens.add(next_page_token, sender_id: sender.id)

    @emails = emails.sort
  end
end
