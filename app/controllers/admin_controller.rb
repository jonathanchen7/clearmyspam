# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_date_range

  def index
    @metrics = AdminMetrics.new(start_date: @start_date, end_date: @end_date)
  end

  private

  def ensure_admin!
    unless current_user.admin?
      redirect_to root_path, alert: "Access denied. Admin privileges required."
    end
  end

  def set_date_range
    range_value = params[:date_range] || "past_week"
    @start_date, @end_date = AdminMetrics.new.parse_date_range(range_value)
  end
end
