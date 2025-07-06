# frozen_string_literal: true

class SendersController < AuthenticatedController
  include DashboardHelper
  include VerbTenseHelper

  set_rate_limit to: 30

  before_action :set_cached_inbox

  before_action :set_sender, if: -> { params[:sender_id].present? || drawer_enabled? }
  before_action :set_drawer_details, only: [:protect, :unprotect, :dispose_all], if: :drawer_enabled?
  before_action :set_senders, only: [:protect, :unprotect, :dispose_all]
  before_action :set_or_refresh_google_auth, only: [:unsubscribe]

  after_action -> { inbox.cache! }, only: [:show, :emails, :protect, :unprotect, :dispose_all]
  after_action -> { Email.write_to_cache(@drawer_sender.id, @drawer_emails) }, only: [:show, :emails]

  attr_reader :sender, :senders, :inbox

  def show
    @drawer_page = params[:page]&.to_i || 1
    @drawer_sender = sender

    render turbo_stream: build_turbo_stream
  end

  def emails
    @drawer_page = params[:page]&.to_i || 1
    @drawer_sender = sender
    @drawer_emails = sender.fetch_emails!(current_user, inbox, page: @drawer_page)
    render turbo_stream: turbo_stream.update("emails-table", Dashboard::EmailsTableComponent.new(emails: @drawer_emails))
  end

  def unsubscribe
    client = Gmail::Client.new(current_user)
    sender_emails, _page_token = client.get_emails!(query: sender.query_string, max_results: 3)

    url = nil
    sender_emails.each do |email|
      url = UnsubscribeLinkFinder.find_link!(current_user, email)
      break if url.present?
    end

    render json: { success: true, url: url }
  end

  def protect
    Sender.protect_all!(current_user, senders.map(&:id))
    inbox.protect_senders(senders.map(&:id))

    toast.success(I18n.t("toasts.protect_senders.success", sender: senders.first.email, count: senders.size).html_safe)

    render turbo_stream: build_turbo_stream(toast: toast)
  end

  def unprotect
    Sender.unprotect_all!(current_user, senders.map(&:id))
    inbox.unprotect_senders(senders.map(&:id))

    toast.success(I18n.t("toasts.unprotect_senders.success", sender: senders.first.email, count: senders.size).html_safe)

    render turbo_stream: build_turbo_stream(toast: toast)
  end

  def dispose_all
    raise "User #{current_user.id} attempted to dispose emails but is disabled." if current_user.disable_dispose?

    actionable_sender_ids = ProtectedSender.actionable_sender_ids(current_user, senders.map(&:id))
    actionable_senders = inbox.senders_lookup(actionable_sender_ids)
    return if actionable_senders.blank?

    result = Gmail::SenderDisposer.new(current_user, actionable_senders).dispose_all!

    disposed_senders = inbox.remove_senders(result.fully_disposed_sender_ids)
    result.partially_disposed_senders.each { |sender, count| inbox.decrease_sender_email_count(sender.id, count) }

    toast_title = I18n.t("toasts.dispose_all_from_senders.success.title", disposing: disposing_verb.capitalize, disposed_count: result.disposed_email_ids.count)
    toast_text = I18n.t("toasts.dispose_all_from_senders.success.text",
                        disposing: disposing_verb.capitalize,
                        disposed_count: result.disposed_email_ids.count,
                        sender: (disposed_senders.first || result.partially_disposed_senders.first&.first).email,
                        count: disposed_senders.size + result.partially_disposed_senders.size).html_safe
    toast.success(toast_title, text: toast_text)

    render turbo_stream: build_turbo_stream(toast: toast)
  end

  private

  def set_sender
    sender_id = params[:sender_id] || params.dig(:drawer_options, :sender_id)
    @sender = inbox.sender_lookup(sender_id)
  end

  def set_senders
    sender_ids = params.require(:sender_ids)
    @senders = inbox.senders_lookup(sender_ids)
  end

  def set_drawer_details
    @drawer_sender = sender
    @drawer_emails = Email.fetch_from_cache(@drawer_sender.id)
    @drawer_page = params.dig(:drawer_options, :page) || 1
  end
end
