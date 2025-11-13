# frozen_string_literal: true

class Admin::SortDropdownComponent < ViewComponent::Base
  def initialize(metrics:, current_sort:)
    @metrics = metrics
    @current_sort = current_sort
  end

  private

  attr_reader :metrics, :current_sort

  def admin_path_with_params
    admin_path(
      date_range: params[:date_range],
      sort_by: current_sort,
      page: params[:page],
      per_page: params[:per_page]
    )
  end
end
