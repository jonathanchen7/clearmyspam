class EmailsController < AuthenticatedController
  include DashboardHelper

  rate_limit to: 30, within: 1.minute, by: -> { current_user.id }

  before_action :validate_email_threads_or_senders_provided, except: %i[dispose_all]
  before_action :validate_drawer_options

  before_action :set_cached_inbox
  before_action :set_senders, except: %i[dispose_all]
  before_action :set_emails, except: %i[dispose_all]
  before_action :set_or_refresh_google_auth, only: %i[dispose]

  after_action -> { inbox.cache! }

  def protect
    inbox.protect!(emails)
    sync_inbox_metrics!(internal_only: true)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(
          toast: toast.success(I18n.t("toasts.protect.success.title", count: email_count, email: emails_noun)),
          drawer_options: params[:drawer_options]
        )
      end
    end
  end

  def unprotect
    inbox.unprotect!(emails)
    sync_inbox_metrics!(internal_only: true)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(
          toast: toast.success(I18n.t("toasts.unprotect.success.title", count: email_count, email: emails_noun)),
          drawer_options: params[:drawer_options]
        )
      end
    end
  end

  def dispose
    present_tense_dispose_verb = archive? ? "archive" : "delete"
    present_participle_dispose_verb = archive? ? "archiving" : "deleting"
    past_tense_dispose_verb = archive? ? "archived" : "deleted"

    if current_user.disable_dispose?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: build_turbo_stream(toast: disabled_dispose_toast)
        end
      end

      return
    end

    dispose_async = emails.size > Rails.configuration.async_dispose_threshold

    ApplicationRecord.transaction do
      if emails.blank?
        toast.info I18n.t("toasts.dispose.no_emails.title", dispose: present_tense_dispose_verb)
      else
        archive? ? inbox.archive!(emails) : inbox.trash!(emails)

        if dispose_async
          Email.dispose_all!(current_user, vendor_ids: emails.map(&:vendor_id))
          toast.info I18n.t("toasts.dispose.async.title", count: email_count, email: emails_noun, disposing: present_participle_dispose_verb)
        else
          vendor_ids = emails.map(&:vendor_id)
          archive? ? Gmail::Client.archive_threads!(current_user, *vendor_ids) : Gmail::Client.trash_threads!(current_user, *vendor_ids)
          toast.success I18n.t("toasts.dispose.success.title", count: email_count, email: emails_noun, disposed: past_tense_dispose_verb)
        end
      end

      if senders.present?
        query = "from:(#{senders.map(&:email).join("|")})"
        remaining_thread_count = Gmail::Client.new(current_user).get_thread_count!(query: query) - emails.count

        if remaining_thread_count.positive?
          toast.text = I18n.t("toasts.dispose.delete_all_from_sender.text",
                              remaining_count: remaining_thread_count,
                              unread: Current.options.unread_only ? " unread" : nil,
                              senders: senders.one? ? senders.first.email : "these #{senders.count} senders",
                              dispose: present_tense_dispose_verb,
                              disposed: past_tense_dispose_verb).html_safe
          toast.with_destructive_cta(
            I18n.t("toasts.dispose.delete_all_from_sender.cta", dispose: present_tense_dispose_verb.capitalize),
            stimulus_data: Views::StimulusData.new(
              controllers: "inbox",
              actions: { "click" => %w[inbox#disposeAllFromSenders toast#dismiss] },
              params: { "inbox" => { "sender_emails" => senders.map(&:email) }, "toast" => { "action" => "disposeAll" } },
              include_controller: true
            )
          )
        end
      end

      sync_inbox_metrics!
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: build_turbo_stream(toast: toast, drawer_options: params[:drawer_options])
      end
    end
  end

  def dispose_all
    sender_emails = params.require(:sender_emails)

    if current_user.disable_dispose?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: build_turbo_stream(toast: disabled_dispose_toast)
        end
      end

      return
    end

    email_ids, _page_token = Gmail::Client.new(current_user).list_emails!(
      max_results: Rails.configuration.sender_dispose_all_max,
      unread_only: Current.options.unread_only,
      query: "from:(#{sender_emails.join("|")})"
    )

    actionable_email_ids = ProtectedEmail.actionable_email_ids(current_user, email_ids)
    actionable_email_ids = actionable_email_ids.first(current_user.remaining_disposal_count) if current_user.unpaid?

    Email.dispose_all!(current_user, vendor_ids: actionable_email_ids)

    respond_to do |format|
      format.turbo_stream do
        present_participle_dispose_verb = archive? ? "archiving" : "deleting"
        senders_text = sender_emails.one? ? sender_emails.first : "these #{sender_emails.count} senders"

        render turbo_stream: build_turbo_stream(
          toast: toast.info(
            I18n.t("toasts.dispose_all.async.title", disposing: present_participle_dispose_verb.capitalize),
            text: I18n.t(
              "toasts.dispose_all.async.text",
              disposing: present_participle_dispose_verb.capitalize,
              unread: Current.options.unread_only ? " unread" : nil,
              senders: senders_text
            ).html_safe
          ),
          drawer_options: params[:drawer_options]
        )
      end
    end
  end

  private

  attr_reader :inbox, :senders, :emails

  def validate_email_threads_or_senders_provided
    if params[:email_ids].blank? && params[:sender_ids].blank?
      raise ArgumentError, "Either email_ids or sender_ids must be provided."
    end
  end

  def validate_drawer_options
    if params.dig(:drawer_options, :enabled).presence && params.dig(:drawer_options, :sender_id).blank?
      raise ArgumentError, "A sender must be provided for drawer actions."
    end
  end

  def set_senders
    if (senders_ids = params[:sender_ids].presence) && senders_ids.is_a?(Array)
      @senders = inbox.senders_lookup(senders_ids.map(&:to_i)).compact
    end
  end

  def set_emails
    @emails = if (email_ids = params[:email_ids].presence)
                inbox.emails.values_at(*email_ids).compact
              elsif senders.present?
                inbox.sender_emails(*senders.map(&:id))
              else
                raise ArgumentError, "Either email_ids or sender_ids must be provided."
              end

    @emails = emails.select(&:actionable?) if action_name == "dispose"
    if current_user.unpaid? && action_name == "dispose"
      @emails = emails.first(current_user.remaining_disposal_count)
    end

    if emails.size > 1000
      @emails = @emails.first(1000)
      Rails.logger.warn("User #{current_user.id} attempted to #{action_name} #{emails.size} emails.")
    end
  end

  def disabled_dispose_toast
    toast.error(
      I18n.t("toasts.dispose.free_trial_limit.title"),
      text: I18n.t("toasts.dispose.free_trial_limit.text", dispose: archive? ? "archive" : "deletion")
    ).with_confirm_cta(
      I18n.t("toasts.dispose.free_trial_limit.cta"),
      stimulus_data: Views::StimulusData.new(
        controllers: "pricing",
        actions: { "click" => "pricing#checkout" },
        values: { "pricing" => { "plan-type" => "monthly" } },
        include_controller: true
      )
    )
  end

  def archive?
    @archive ||= Current.options.archive
  end

  def emails_noun
    "email".pluralize(email_count)
  end

  def email_count
    emails.count
  end
end
