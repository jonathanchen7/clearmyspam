# frozen_string_literal: true

class SendersController < AuthenticatedController
  include DashboardHelper

  rate_limit to: 30, within: 1.minute, by: -> { current_user.id }

  before_action :set_cached_inbox
  before_action :set_sender
  before_action :set_page

  before_action :fetch_emails, only: [:show, :update_page]
  before_action :set_emails, only: [:protect, :unprotect, :dispose]
  before_action :set_or_refresh_google_auth, only: [:unsubscribe]

  after_action -> { inbox.cache! }, only: [:show, :update_page]
  after_action -> { Email.write_to_cache(sender.id, emails) }

  attr_reader :sender, :inbox, :emails, :selected_emails, :page

  def show
    sender.get_email_count!(current_user)

    render turbo_stream: turbo_stream.append("inbox", partial: "dashboard/sender_drawer", locals: { sender:, emails: })
  end

  def update_page
    replace_drawer(page:)
  end

  def protect
    Email.protect_all!(current_user, selected_emails.map(&:vendor_id))
    selected_emails.each { |email| email.protected = true }

    toast_title = I18n.t("toasts.protect.success.title", count: selected_emails.count, email: "Email")
    replace_drawer(page:, toast: toast.success(toast_title))
  end

  def unprotect
    Email.unprotect_all!(current_user, selected_emails.map(&:vendor_id))
    selected_emails.each { |email| email.protected = false }

    toast_title = I18n.t("toasts.unprotect.success.title", count: selected_emails.count, email: "Email")
    replace_drawer(page:, toast: toast.success(toast_title))
  end

  def dispose
    past_tense_dispose_verb = current_user.option.archive? ? "archived" : "deleted"
    toast_title = I18n.t("toasts.dispose.success.title", count: selected_emails.count, email: "email".pluralize(selected_emails.count), disposed: past_tense_dispose_verb)

    Email.dispose_all!(current_user, vendor_ids: selected_emails.map(&:vendor_id))
    emails.reject! { |email| selected_emails.include?(email) }

    replace_drawer(page:, toast: toast.success(toast_title))
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

  def set_page
    @page = params.dig(:drawer_options, :page) || 1
  end

  def set_emails
    @emails = Email.fetch_from_cache(sender.id)
  end

  def fetch_emails
    page_token = page == 1 ? nil : inbox.page_tokens.for(page: page - 1, sender_id: sender.id)

    emails, next_page_token = sender.get_emails!(current_user, page_token: page_token)
    inbox.page_tokens.add(next_page_token, sender_id: sender.id)

    @emails = emails.sort
  end

  def replace_drawer(page: 1, toast: nil)
    stream = [turbo_stream.replace("sender_drawer", partial: "dashboard/sender_drawer", locals: { sender:, emails:, page: })]
    stream << toast_stream(toast) if toast.present?

    render turbo_stream: stream
  end

  def selected_emails
    all_selected_emails = if params[:email_ids].present?
                            email_ids = params.require(:email_ids)
                            emails.select { |email| email_ids.include?(email.vendor_id) }
                          else
                            emails
                          end

    action_name == "dispose" ? all_selected_emails.select(&:actionable?) : all_selected_emails
  end
end
