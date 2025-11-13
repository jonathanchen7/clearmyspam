# frozen_string_literal: true

class Admin::UsersTableComponent < ViewComponent::Base
  def initialize(users:, metrics:)
    @users = users
    @metrics = metrics
  end

  private

  attr_reader :users, :metrics

  def plan_type_display(user)
    return "N/A" unless user.active_account_plan

    case user.active_account_plan.plan_type
    when "trial"
      "Trial"
    when "weekly"
      "Pro (Weekly)"
    when "monthly"
      "Pro (Monthly)"
    when "yearly"
      "Pro (Yearly)"
    else
      user.active_account_plan.plan_type.humanize
    end
  end

  def plan_type_color_class(user)
    return "bg-gray-100 text-gray-700" unless user.active_account_plan

    case user.active_account_plan.plan_type
    when "trial"
      "bg-gray-100 text-gray-700"
    when "weekly"
      "bg-orange-100 text-orange-700"
    when "monthly"
      "bg-blue-100 text-blue-700"
    when "yearly"
      "bg-green-100 text-green-700"
    else
      "bg-gray-100 text-gray-700"
    end
  end

  def date_range
    return nil unless metrics.start_date && metrics.end_date

    metrics.start_date.to_date..metrics.end_date.to_date
  end

  def total_disposed_count(user)
    user.metrics&.disposed_count || 0
  end

  def disposed_in_range_count(user)
    return 0 unless user.metrics && date_range

    user.metrics.disposed_count(range: date_range)
  end

  def move_count(user)
    return 0 unless user.metrics

    date_range ? user.metrics.moved_count(range: date_range) : user.metrics.moved_count
  end

  def unsubscribe_count(user)
    return 0 unless user.metrics

    if date_range
      user.metrics.successful_unsubscribe_count(range: date_range) + user.metrics.failed_unsubscribe_count(range: date_range)
    else
      (user.metrics.successful_unsubscribe_count || 0) + (user.metrics.failed_unsubscribe_count || 0)
    end
  end

  def pagination_params
    {
      date_range: params[:date_range],
      sort_by: params[:sort_by],
      per_page: params[:per_page]
    }
  end
end
