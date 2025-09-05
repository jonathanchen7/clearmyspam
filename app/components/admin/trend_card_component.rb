# frozen_string_literal: true

class Admin::TrendCardComponent < ViewComponent::Base
  def initialize(title:, value:, icon:, subtitle: nil)
    @title = title
    @value = value
    @icon = icon
    @subtitle = subtitle
  end

  private

  attr_reader :title, :value, :icon, :subtitle
end
