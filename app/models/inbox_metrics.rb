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
    internal_metrics = user.email_threads.group(:protected, :archived, :trashed).count
    @protected = internal_metrics.fetch([true, false, false], 0)
    @archived = internal_metrics.fetch([false, true, false], 0)
    @trashed = internal_metrics.fetch([false, false, true], 0)

    @updated_at = Time.current
  end

  def sync!(user)
    threads_total, threads_unread = Gmail::Client.get_inbox_metrics!(user)
    @total = threads_total
    @unread = threads_unread

    sync_internal!(user)

    @updated_at = Time.current
  end

  def populated?
    updated_at.present?
  end
end
