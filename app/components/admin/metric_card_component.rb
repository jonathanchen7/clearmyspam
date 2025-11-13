# frozen_string_literal: true

class Admin::MetricCardComponent < ViewComponent::Base
  def initialize(title:, value:, subtitle: nil)
    @title = title
    @value = value

    @subtitle = subtitle
  end

  private

  attr_reader :title, :value, :subtitle
end
