module Dashboard
  class InboxMetricsPillComponent < ViewComponent::Base
    include ActionView::Helpers::NumberHelper

    def initialize(value, icon:, suffix:)
      @value = value || 0
      @pill_icon = icon
      @suffix = suffix
    end

    def text
      "#{number_with_delimiter(@value)} #{@suffix}"
    end
  end
end
