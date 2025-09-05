# frozen_string_literal: true

class Admin::PaginatedTableComponent < ViewComponent::Base
  def initialize(title:, users:, columns:, pagination_params: {})
    @title = title
    @users = users
    @columns = columns
    @pagination_params = pagination_params
  end

  private

  attr_reader :title, :users, :columns, :pagination_params

  def user_avatar(user)
    if user.image.present?
      image_tag user.image, class: "h-10 w-10 rounded-full", alt: ""
    else
      content_tag :div, class: "h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center" do
        content_tag :span, user.name.first.upcase, class: "text-sm font-medium text-gray-700"
      end
    end
  end

  def user_plan_badge(user)
    if user.active_pro?
      content_tag :span, "Pro", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
    elsif user.unpaid?
      content_tag :span, "Trial", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
    else
      content_tag :span, "Inactive", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
    end
  end

  def onboarding_status_badge(user)
    if user.onboarding_completed?
      content_tag :span, "Completed", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
    else
      content_tag :span, "Pending", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800"
    end
  end

  def pagination_info
    return "" unless users.respond_to?(:current_page)

    start_num = ((users.current_page - 1) * users.limit_value) + 1
    end_num = [users.current_page * users.limit_value, users.total_count].min

    "Showing #{start_num}-#{end_num} of #{users.total_count} users"
  end

  def page_size_options
    [10, 25, 50, 100]
  end

  def current_page_size
    users.respond_to?(:limit_value) ? users.limit_value : 25
  end
end
