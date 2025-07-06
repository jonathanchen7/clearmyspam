class EmailsController < AuthenticatedController
  include DashboardHelper
  include VerbTenseHelper

  set_rate_limit to: 30

  before_action :set_cached_inbox
  before_action :set_drawer_details, if: :drawer_enabled?

  after_action -> { inbox.cache! }
  after_action -> { Email.write_to_cache(@drawer_sender.id, @drawer_emails) }, if: :drawer_enabled?

  def protect
    selected_email_ids = params.require(:email_ids)
    Email.protect_all!(current_user, selected_email_ids)
    @drawer_emails.each { |email| email.protected = true if selected_email_ids.include?(email.vendor_id) }

    sync_inbox_metrics!(internal_only: true)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(
          toast: toast.success(I18n.t("toasts.protect.success.title", count: selected_email_ids.count))
        )
      end
    end
  end

  def unprotect
    selected_email_ids = params.require(:email_ids)
    Email.unprotect_all!(current_user, selected_email_ids)
    @drawer_emails.each { |email| email.protected = false if selected_email_ids.include?(email.vendor_id) }

    sync_inbox_metrics!(internal_only: true)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(
          toast: toast.success(I18n.t("toasts.unprotect.success.title", count: selected_email_ids.count))
        )
      end
    end
  end

  def dispose
    raise "User #{current_user.id} attempted to dispose emails but is disabled." if current_user.disable_dispose?

    ApplicationRecord.transaction do
      selected_email_ids = params.require(:email_ids)
      actionable_email_ids = ProtectedEmail.actionable_email_ids(current_user, selected_email_ids)
      actionable_email_ids = actionable_email_ids.first(current_user.remaining_disposal_count) if current_user.unpaid?

      if actionable_email_ids.blank?
        toast.info I18n.t("toasts.dispose.no_emails.title", dispose: dispose_verb)
      else
        Email.dispose_all!(current_user, vendor_ids: actionable_email_ids)
        @drawer_emails&.reject! { |email| actionable_email_ids.include?(email.vendor_id) }
        inbox.decrease_sender_email_count(@drawer_sender.id, actionable_email_ids.count)
        toast.success I18n.t("toasts.dispose.success.title", count: actionable_email_ids.count, disposed: disposed_verb)
      end
    end

    render turbo_stream: build_turbo_stream(toast: toast)
  end

  private

  attr_reader :inbox

  def set_drawer_details
    @drawer_sender = @inbox.sender_lookup(params.dig(:drawer_options, :sender_id))
    @drawer_emails = Email.fetch_from_cache(@drawer_sender.id)
    @drawer_page = params.dig(:drawer_options, :page)

    raise ArgumentError, "Invalid sender ID: #{params.dig(:drawer_options, :sender_id)}" if @drawer_sender.blank?
  end
end
