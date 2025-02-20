# frozen_string_literal: true

module DashboardHelper
  module ButtonTypes
    PRIMARY = "primary"
    SECONDARY = "secondary"
    DANGER = "danger"
    TEXT = "text"
  end

  def build_turbo_stream(senders_table: true, toolbar: true, toast: nil, drawer_options: {})
    stream = []

    stream << turbo_stream.replace("senders_table", partial: "dashboard/senders_table") if senders_table
    stream << turbo_stream.replace("toolbar", partial: "dashboard/toolbar") if toolbar
    stream << turbo_stream.prepend("notifications", toast) if toast.present? && toast.title.present?

    if drawer_options.present? && drawer_options[:enabled]
      stream << turbo_stream.replace(
        "sender_drawer",
        partial: "dashboard/sender_drawer",
        locals: { sender: @inbox.sender_lookup(drawer_options[:sender_id]) }
      )
    end

    stream
  end

  def protected_thread_count(email_threads)
    email_threads.select(&:protected?).count
  end

  def actionable_thread_count(email_threads)
    email_threads.select(&:actionable?).count
  end
end
