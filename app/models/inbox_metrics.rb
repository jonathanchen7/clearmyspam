# frozen_string_literal: true

class InboxMetrics
  attr_reader :total, :unread, :protected, :archived, :trashed, :updated_at

  def initialize
    @total = 0
    @unread = 0
    @protected = 0
    @archived = 0
    @trashed = 0
  end

  def sync_internal!(user)
    @protected = user.protected_emails.count
    @archived = user.metrics.archived_count
    @trashed = user.metrics.trashed_count

    @updated_at = Time.current
  end

  def sync!(user)
    threads_total, threads_unread = Gmail::Client.get_inbox_metrics!(user)
    @total = threads_total
    @unread = threads_unread

    if user.metrics.initial_total_threads.zero?
      user.metrics.update!(
        initial_total_threads: threads_total,
        initial_unread_threads: threads_unread,
        total_threads: threads_total,
        unread_threads: threads_unread
      )
    else
      user.metrics.update!(
        total_threads: threads_total,
        unread_threads: threads_unread
      )
    end

    sync_internal!(user)

    @updated_at = Time.current
  end

  def populated?
    updated_at.present?
  end
end
