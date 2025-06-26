# frozen_string_literal: true

class SendersController < AuthenticatedController
  include DashboardHelper
  include VerbTenseHelper

  rate_limit to: 30, within: 1.minute, by: -> { current_user.id }

  before_action :set_cached_inbox

  before_action :set_sender, only: [:show, :unsubscribe]

  before_action :set_senders, only: [:protect, :unprotect, :dispose_all]
  before_action :set_or_refresh_google_auth, only: [:unsubscribe]

  after_action -> { inbox.cache! }, only: [:show, :protect, :unprotect, :dispose_all]
  after_action -> { Email.write_to_cache(@drawer_sender.id, @drawer_emails) }, only: [:show]

  attr_reader :sender, :senders, :inbox

  def show
    @drawer_page = params[:page]&.to_i || 1
    @drawer_sender = sender
    @drawer_emails = sender.fetch_emails!(current_user, inbox, page: @drawer_page)

    sender.get_email_count!(current_user)

    render turbo_stream: build_turbo_stream
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

  # TODO: Refactor this into a model!
  def dispose_all
    raise "User #{current_user.id} attempted to dispose emails but is disabled." if current_user.disable_dispose?

    actionable_sender_ids = ProtectedSender.actionable_sender_ids(current_user, senders.map(&:id))
    actionable_senders = inbox.senders_lookup(actionable_sender_ids)

    all_actionable_email_ids = []
    fully_disposed_sender_ids = []
    partially_disposed_senders = {}

    actionable_senders.each do |sender|
      email_ids, _page_token = sender.list_emails!(current_user)

      actionable_email_ids = ProtectedEmail.actionable_email_ids(current_user, email_ids)
      actionable_email_ids = actionable_email_ids.first(current_user.remaining_disposal_count) if current_user.unpaid?

      all_actionable_email_ids.concat(actionable_email_ids)

      if actionable_email_ids.count >= sender.email_count
        fully_disposed_sender_ids << sender.id
      elsif actionable_email_ids.count > 0
        partially_disposed_senders[sender] = actionable_email_ids.count
      end
    end

    Email.dispose_all!(current_user, vendor_ids: all_actionable_email_ids)

    disposed_senders = inbox.remove_senders(fully_disposed_sender_ids)
    partially_disposed_senders.each { |sender, count| inbox.decrease_sender_email_count(sender.id, count) }

    toast_title = I18n.t("toasts.dispose_all_from_senders.success.title", disposing: disposing_verb.capitalize, disposed_count: all_actionable_email_ids.count)
    toast_text = I18n.t("toasts.dispose_all_from_senders.success.text",
                        disposing: disposing_verb.capitalize,
                        disposed_count: all_actionable_email_ids.count,
                        sender: (disposed_senders.first || partially_disposed_senders.first.first).email,
                        count: disposed_senders.size + partially_disposed_senders.size).html_safe
    toast.success(toast_title, text: toast_text)

    render turbo_stream: build_turbo_stream(toast: toast)
  end

  private

  def set_sender
    sender_id = params.require(:sender_id)
    @sender = inbox.sender_lookup(sender_id)
  end

  def set_senders
    sender_ids = params.require(:sender_ids)
    @senders = inbox.senders_lookup(sender_ids)
  end
end
