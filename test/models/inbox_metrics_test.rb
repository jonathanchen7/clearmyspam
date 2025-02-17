# frozen_string_literal: true

require "test_helper"

class InboxMetricsTest < ActiveSupport::TestCase
  setup { freeze_time }

  test "#sync_internal! updates protected, archived, and trashed counts" do
    user = create(:user)
    _protected_emails = create_list(:email_thread, 1, user: user, protected: true)
    _archived_emails = create_list(:email_thread, 2, user: user, archived: true)
    _trashed_emails = create_list(:email_thread, 3, user: user, trashed: true)
    _external_emails = create_list(:email_thread, 3)

    metrics = InboxMetrics.new
    assert_equal 0, metrics.protected
    assert_equal 0, metrics.archived
    assert_equal 0, metrics.trashed
    assert_nil metrics.updated_at

    metrics.sync_internal!(user)

    assert_equal 1, metrics.protected
    assert_equal 2, metrics.archived
    assert_equal 3, metrics.trashed
    assert_equal Time.current, metrics.updated_at
  end

  test "#sync! fetches Gmail metrics and updates internal metrics" do
    Gmail::Client.expects(:get_inbox_metrics!).returns([10, 5])

    user = create(:user)
    _protected_email = create(:email_thread, user: user, protected: true)
    _archived_email = create(:email_thread, user: user, archived: true)
    _trashed_email = create(:email_thread, user: user, trashed: true)
    _external_email = create(:email_thread)

    metrics = InboxMetrics.new
    assert_equal 0, metrics.total
    assert_equal 0, metrics.unread
    assert_equal 0, metrics.protected
    assert_equal 0, metrics.archived
    assert_equal 0, metrics.trashed
    assert_nil metrics.updated_at

    metrics.sync!(user)

    assert_equal 10, metrics.total
    assert_equal 5, metrics.unread
    assert_equal 1, metrics.protected
    assert_equal 1, metrics.archived
    assert_equal 1, metrics.trashed
    assert_equal Time.current, metrics.updated_at
  end

  test "#populated? returns true if updated_at is present" do
    metrics = InboxMetrics.new
    assert_not metrics.populated?

    metrics.instance_variable_set(:@updated_at, Time.current)
    assert metrics.populated?
  end
end
