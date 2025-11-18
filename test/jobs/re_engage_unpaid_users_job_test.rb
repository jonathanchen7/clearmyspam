require "test_helper"

class ReEngageUnpaidUsersJobTest < ActiveSupport::TestCase
  test "#active_unpaid_users filters users correctly based on all criteria" do
    job = ReEngageUnpaidUsersJob.new
    job.instance_variable_set(:@date_range, 1.week.ago..Time.current)

    eligible_user_1 = create(:user, last_login_at: 3.days.ago, created_at: 5.days.ago)
    eligible_user_2 = create(:user, :with_re_engagement_email, last_login_at: 1.day.ago, created_at: 5.days.ago)

    # Users that should be excluded
    paid_user = create(:user, last_login_at: 3.days.ago, created_at: 5.days.ago)
    create(:account_plan, :pro, user: paid_user)
    user_outside_date_range = create(:user, last_login_at: 2.weeks.ago, created_at: 3.weeks.ago)
    user_no_marketing_emails = create(:user, last_login_at: 3.days.ago, send_marketing_emails: false, created_at: 5.days.ago)
    user_too_new = create(:user, last_login_at: 3.hours.ago, created_at: 1.day.ago)
    user_with_both = create(:user, :with_re_engagement_email, :with_re_engagement_reminder_email, last_login_at: 3.days.ago, created_at: 5.days.ago)

    user_ids = job.active_unpaid_users.map(&:id)

    assert_includes user_ids, eligible_user_1.id, "includes user with no re-engagement emails"
    assert_includes user_ids, eligible_user_2.id, "includes user with re_engagement email"

    assert_not_includes user_ids, paid_user.id, "excludes paid users"
    assert_not_includes user_ids, user_outside_date_range.id, "excludes users outside date range"
    assert_not_includes user_ids, user_no_marketing_emails.id, "excludes users with send_marketing_emails false"
    assert_not_includes user_ids, user_too_new.id, "excludes users created less than 2 days ago"
    assert_not_includes user_ids, user_with_both.id, "excludes users with both emails"
  end
end
