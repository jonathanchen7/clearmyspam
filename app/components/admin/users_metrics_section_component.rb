# frozen_string_literal: true

class Admin::UsersMetricsSectionComponent < ViewComponent::Base
  def initialize(metrics:)
    @metrics = metrics
  end

  private

  attr_reader :metrics
end
