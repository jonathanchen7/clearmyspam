# frozen_string_literal: true

module DashboardHelper
  module ButtonTypes
    PRIMARY = "primary"
    SECONDARY = "secondary"
    DANGER = "danger"
    TEXT = "text"
  end

  def build_turbo_stream(senders_table: true, toolbar: true, toast: nil)
    stream = []

    stream << turbo_stream.replace("senders_table", partial: "dashboard/senders_table") if senders_table
    stream << turbo_stream.replace("toolbar", partial: "dashboard/toolbar") if toolbar
    stream << turbo_stream.prepend("notifications", toast) if toast.present? && toast.title.present?

    if drawer_enabled?
      stream << turbo_stream.replace(
        "sender_drawer",
        partial: "dashboard/sender_drawer",
        locals: { sender: @drawer_sender, emails: @drawer_emails, page: @drawer_page }
      )
    end

    stream
  end

  def archive?
    current_user.option.archive
  end

  def drawer_enabled?
    @drawer_enabled ||= params.dig(:drawer_options, :enabled).presence || (params[:controller] == "senders" && params[:action] == "show")
  end

  def toast_stream(toast)
    turbo_stream.prepend("notifications", toast)
  end

  def render_toast(toast)
    render turbo_stream: turbo_stream.prepend("notifications", toast)
  end
end
