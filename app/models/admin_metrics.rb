# frozen_string_literal: true

class AdminMetrics
  attr_reader :start_date, :end_date

  def initialize(start_date: nil, end_date: nil)
    @start_date = start_date || 7.days.ago.beginning_of_day
    @end_date = end_date || Time.current.end_of_day
  end

  def user_signup_count
    User.where(created_at: start_date..end_date).count
  end

  def active_user_count
    User.where(last_login_at: start_date..end_date).count
  end

  def recently_logged_in_users
    User.where(last_login_at: start_date..end_date).order(last_login_at: :desc).limit(10)
  end

  def recently_signed_up_users
    User.where(created_at: start_date..end_date).order(created_at: :desc).limit(10)
  end

  def emails_disposed
    total_archived = Metrics.joins(:user)
                            .where(users: { created_at: start_date..end_date })
                            .sum(:archived_count)

    total_trashed = Metrics.joins(:user)
                           .where(users: { created_at: start_date..end_date })
                           .sum(:trashed_count)

    {
      archived: total_archived,
      trashed: total_trashed,
      total: total_archived + total_trashed
    }
  end

  def top_users_by_disposal
    User.joins(:metrics)
        .where(metrics: { updated_at: start_date..end_date })
        .select("users.*, (metrics.archived_count + metrics.trashed_count) as total_disposed")
        .order("total_disposed DESC")
        .limit(10)
  end

  def top_users_by_activity
    User.where(last_login_at: start_date..end_date)
        .order(last_login_at: :desc)
        .limit(10)
  end

  def subscription_metrics
    {
      total_users: User.count,
      pro_users: User.joins(:active_account_plan).where(account_plans: { plan_type: AccountPlan::PRO_PLAN_TYPES }).count,
      trial_users: User.joins(:active_account_plan).where(account_plans: { plan_type: "trial" }).count,
      conversion_rate: calculate_conversion_rate
    }
  end

  def onboarding_completion_rate
    total_users = User.where(created_at: start_date..end_date).count
    completed_users = User.where(created_at: start_date..end_date, onboarding_completed_at: start_date..end_date).count

    return 0 if total_users.zero?

    (completed_users.to_f / total_users * 100).round(2)
  end

  def pending_disposals_count
    PendingEmailDisposal.where(created_at: start_date..end_date).count
  end

  def global_metrics
    {
      total_users: User.count,
      total_emails_disposed: Metrics.sum(:archived_count) + Metrics.sum(:trashed_count),
      onboarding_completion_rate: global_onboarding_completion_rate,
      conversion_rate: global_conversion_rate
    }
  end

  def date_range_options
    [
      { label: "Past Week", value: "past_week" },
      { label: "Past Month", value: "past_month" },
      { label: "Past 3 Months", value: "past_3_months" },
      { label: "Past Year", value: "past_year" },
      { label: "All Time", value: "all_time" }
    ]
  end

  def parse_date_range(range_value)
    case range_value
    when "past_week"
      [7.days.ago.beginning_of_day, Time.current.end_of_day]
    when "past_month"
      [30.days.ago.beginning_of_day, Time.current.end_of_day]
    when "past_3_months"
      [3.months.ago.beginning_of_day, Time.current.end_of_day]
    when "past_year"
      [1.year.ago.beginning_of_day, Time.current.end_of_day]
    when "all_time"
      [Date.new(2000, 1, 1).beginning_of_day, Time.current.end_of_day]
    else
      [7.days.ago.beginning_of_day, Time.current.end_of_day]
    end
  end

  def calculate_conversion_rate
    total_users = User.where(created_at: start_date..end_date).count
    pro_users = User.joins(:active_account_plan)
                    .where(account_plans: { plan_type: AccountPlan::PRO_PLAN_TYPES })
                    .where(created_at: start_date..end_date)
                    .count

    return 0 if total_users.zero?

    (pro_users.to_f / total_users * 100).round(2)
  end

  private

  def global_conversion_rate
    total_users = User.count
    pro_users = User.joins(:active_account_plan).where(account_plans: { plan_type: AccountPlan::PRO_PLAN_TYPES }).count

    return 0 if total_users.zero?

    (pro_users.to_f / total_users * 100).round(2)
  end

  def global_onboarding_completion_rate
    total_users = User.count
    completed_users = User.where.not(onboarding_completed_at: nil).count

    return 0 if total_users.zero?

    (completed_users.to_f / total_users * 100).round(2)
  end

  def average_emails_per_user
    total_users = User.count
    total_emails = Metrics.sum(:archived_count) + Metrics.sum(:trashed_count)

    return 0 if total_users.zero?

    (total_emails.to_f / total_users).round(1)
  end
end
