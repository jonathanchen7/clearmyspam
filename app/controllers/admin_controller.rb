# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_date_range
  before_action :set_pagination_params

  def index
    @metrics = AdminMetrics.new(
      start_date: @start_date,
      end_date: @end_date,
      page: @page,
      per_page: @per_page
    )
    @active_tab = valid_tab(params[:tab]) || "signups"
  end

  def tab
    @metrics = AdminMetrics.new(
      start_date: @start_date,
      end_date: @end_date,
      page: @page,
      per_page: @per_page
    )
    @active_tab = valid_tab(params[:tab_id]) || "signups"

    respond_to do |format|
      format.html { render_tab_partial(@active_tab, @metrics) }
      format.turbo_stream { render_tab_partial(@active_tab, @metrics) }
    end
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

  def set_pagination_params
    @page = params[:page] || 1
    @per_page = params[:per_page] || 25
  end

  def valid_tab(tab_id)
    allowed_tabs = %w[usage signups logins]
    allowed_tabs.include?(tab_id) ? tab_id : nil
  end

  def render_tab_partial(tab_name, metrics)
    case tab_name
    when "usage"
      render partial: "admin/tabs/usage", locals: { metrics: metrics }
    when "signups"
      render partial: "admin/tabs/signups", locals: { metrics: metrics }
    when "logins"
      render partial: "admin/tabs/logins", locals: { metrics: metrics }
    else
      render partial: "admin/tabs/signups", locals: { metrics: metrics }
    end
  end
end
