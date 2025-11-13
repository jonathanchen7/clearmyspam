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

  after_action -> { inbox.cache! }, only: [:show, :emails, :protect, :unprotect, :dispose_all, :move_all]
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
    if sender.blank?
      toast.error("Error", text: "We could not find any emails from this sender.")
      render turbo_stream: build_turbo_stream(toast: toast)
      return
    end

    client = Gmail::Client.new(current_user)
    sender_emails, _page_token = client.get_emails!(query: sender.query_string, max_results: 3)

    url = nil
    successful_unsubscribe = false
    sender_emails.each do |email|
      begin
        url = UnsubscribeLinkFinder.find_link!(current_user, email)
      rescue => e
        Honeybadger.notify(e)
      end

      if url.present?
        successful_unsubscribe = true
        break
      end
    end

    if successful_unsubscribe
      current_user.daily_metric.increment_successful_unsubscribe_count!
    else
      current_user.daily_metric.increment_failed_unsubscribe_count!
    end

    render json: { success: true, url: url }
  end

  def labels_modal
    @sender_ids = params[:sender_ids].present? ? JSON.parse(params[:sender_ids]) : []
    @labels = inbox.labels.sort_by(&:name)

    render turbo_stream: turbo_stream.replace("labels_modal", partial: "dashboard/labels_modal")
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
    if current_user.disable_dispose?
      toast.error(
        I18n.t("toasts.dispose.free_trial_limit.title", dispose: dispose_verb),
        text: I18n.t("toasts.dispose.free_trial_limit.text", dispose: dispose_verb),
      ).with_confirm_cta(
        I18n.t("toasts.dispose.free_trial_limit.cta"),
        stimulus_data: Views::StimulusData.new(
          controllers: "pricing",
          actions: { "click" => "pricing#checkout" },
          values: { "pricing" => { "plan-type" => "monthly" } },
          include_controller: true
        )
      )
    else
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
                          sender: (disposed_senders.first || result.partially_disposed_senders.first&.first)&.email,
                          count: disposed_senders.size + result.partially_disposed_senders.size).html_safe
      toast.success(toast_title, text: toast_text)
    end

    render turbo_stream: build_turbo_stream(toast: toast)
  end

  def move_all
    sender_ids = params.require(:sender_ids)
    label_id = params.require(:label_id)

    label = inbox.labels.find { |l| l.id == label_id }
    if label.blank?
      toast.error("Label not found.")
      render turbo_stream: build_turbo_stream(toast: toast)
      return
    end

    senders_to_move = inbox.senders_lookup(sender_ids)
    if senders_to_move.blank?
      toast.error("No senders found.")
      render turbo_stream: build_turbo_stream(toast: toast)
      return
    end

    thread_ids_to_move = senders_to_move.flat_map do |sender|
      Gmail::Client.new(current_user).list_emails!(query: sender.query_string).first
    end

    if thread_ids_to_move.any?
      thread_ids_to_move.each_slice(1000) do |thread_ids_batch|
        email_task_attributes = thread_ids_batch.map do |thread_id|
          {
            vendor_id: thread_id,
            task_type: "move",
            payload: { label_id: label.id, label_name: label.name }
          }
        end
        current_user.email_tasks.upsert_all(email_task_attributes, unique_by: %i[user_id task_type vendor_id])
      end

      ProcessEmailTasksJob.perform_later(current_user)
      inbox.remove_senders(senders_to_move.map(&:id))

      toast.success(I18n.t("toasts.move_all_from_senders.success",
                          sender: senders_to_move.first.email,
                          count: senders_to_move.size,
                          emails_count: thread_ids_to_move.size,
                          label: label.name).html_safe)
    else
      toast.error(I18n.t("toasts.move_all_from_senders.no_emails",
                        sender: senders_to_move.first.email,
                        count: senders_to_move.size).html_safe)
    end

    render turbo_stream: build_turbo_stream(toast: toast)
  end

  private

  def set_sender
    sender_id = params[:sender_id] || params.dig(:drawer_options, :sender_id)
    @sender = inbox.sender_lookup(sender_id)
  end

  def set_senders
    sender_ids = params.require(:sender_ids)
    @senders = inbox.senders_lookup(sender_ids).compact
  end

  def set_drawer_details
    @drawer_sender = sender
    @drawer_emails = Email.fetch_from_cache(@drawer_sender.id)
    @drawer_page = params.dig(:drawer_options, :page) || 1
  end
end
