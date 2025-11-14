# frozen_string_literal: true

class AdminMetrics
  attr_reader :start_date, :end_date, :page, :per_page, :sort_by

  def initialize(start_date: nil, end_date: nil, page: 1, per_page: 25, sort_by: "disposal_count")
    @start_date = start_date || 7.days.ago.beginning_of_day
    @end_date = end_date || Time.current.end_of_day
    @page = page.to_i
    @per_page = per_page.to_i
    @sort_by = sort_by
  end

  def signed_up_users_count
    User.where(created_at: start_date..end_date).count
  end

  def logged_in_users_count
    User.where(last_login_at: start_date..end_date).count
  end

  def users_converted_count
    User.joins(:account_plans)
        .where(account_plans: { plan_type: AccountPlan::PRO_PLAN_TYPES })
        .where(account_plans: { created_at: start_date..end_date })
        .distinct
        .count
  end

  def conversion_rate
    total_users = logged_in_users_count
    return 0 if total_users.zero?

    converted_users = users_converted_count
    (converted_users.to_f / total_users * 100).round(2)
  end

  def total_disposed_emails
    DailyMetrics.where(date: start_date.to_date..end_date.to_date)
                .sum("archived_count + trashed_count")
  end

  def total_archived_emails
    DailyMetrics.where(date: start_date.to_date..end_date.to_date)
                .sum(:archived_count)
  end

  def total_trashed_emails
    DailyMetrics.where(date: start_date.to_date..end_date.to_date)
                .sum(:trashed_count)
  end

  def average_emails_disposed_per_user
    total_users = User.where(last_login_at: start_date..end_date).count
    return 0 if total_users.zero?

    (total_disposed_emails.to_f / total_users).round(1)
  end

  def total_emails_moved
    DailyMetrics.where(date: start_date.to_date..end_date.to_date)
                .sum(:moved_count)
  end

  def total_successful_unsubscribes
    DailyMetrics.where(date: start_date.to_date..end_date.to_date)
                .sum(:successful_unsubscribe_count)
  end

  def total_failed_unsubscribes
    DailyMetrics.where(date: start_date.to_date..end_date.to_date)
                .sum(:failed_unsubscribe_count)
  end

  def users
    base_query = User.includes(:metrics, :active_account_plan)
                     .where(last_login_at: start_date..end_date)
                     .left_joins(:metrics)
                     .select("users.*, COALESCE(metrics.archived_count, 0) + COALESCE(metrics.trashed_count, 0) as total_disposed")

    case sort_by
    when "disposal_count"
      base_query.order("total_disposed DESC")
    when "signup_date"
      base_query.order(created_at: :desc)
    when "login_date"
      base_query.order(last_login_at: :desc)
    else
      base_query.order("total_disposed DESC")
    end.page(page).per(per_page)
  end

  def date_range_options
    [
      { label: "Yesterday", value: "yesterday" },
      { label: "Past Week", value: "past_week" },
      { label: "Past Month", value: "past_month" },
      { label: "Past 3 Months", value: "past_3_months" },
      { label: "Past Year", value: "past_year" },
      { label: "All Time", value: "all_time" }
    ]
  end

  def sort_options
    [
      { label: "Sign Up Date", value: "signup_date" },
      { label: "Usage (Disposal Count)", value: "disposal_count" },
      { label: "Login Date", value: "login_date" }
    ]
  end

  def parse_date_range(range_value)
    case range_value
    when "yesterday"
      [1.day.ago.beginning_of_day, 1.day.ago.end_of_day]
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
end
