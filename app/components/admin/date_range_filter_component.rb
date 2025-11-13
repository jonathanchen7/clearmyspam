# frozen_string_literal: true

class Admin::DateRangeFilterComponent < ViewComponent::Base
  def initialize(metrics:, current_date_range:)
    @metrics = metrics
    @current_date_range = current_date_range
  end

  private

  attr_reader :metrics, :current_date_range

  def admin_path_with_params
    admin_path(
      date_range: current_date_range,
      sort_by: params[:sort_by],
      page: params[:page],
      per_page: params[:per_page]
    )
  end
end
