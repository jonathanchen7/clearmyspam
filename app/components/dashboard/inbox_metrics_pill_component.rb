module Dashboard
  class InboxMetricsPillComponent < ViewComponent::Base
    def initialize(value, icon:, suffix:)
      @value = value || 0
      @icon = icon
      @suffix = suffix
    end

    def text
      "#{@value} #{@suffix}"
    end
  end
end
