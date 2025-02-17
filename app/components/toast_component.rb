class ToastComponent < ViewComponent::Base
  module TYPE
    SUCCESS = "success"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"
  end

  def initialize(title: nil, text: nil, type: TYPE::INFO, icon: nil, cta_text: nil, cta_stimulus_data: nil, placeholder: false)
    raise "cta_text and cta_stimulus_data must be provided together" if cta_text.nil? ^ cta_stimulus_data.nil?

    @title = title
    @text = text
    @type = type
    @icon = icon
    @cta_text = cta_text
    @cta_stimulus_data = cta_stimulus_data
    @placeholder = placeholder
  end

  def icon_name
    return @icon if @icon

    case @type
    when TYPE::SUCCESS
      "circle-check"
    when TYPE::ERROR
      "circle-exclamation"
    when TYPE::WARNING
      "triangle-exclamation"
    when TYPE::INFO
      "circle-info"
    else
      raise "Invalid toast type"
    end
  end

  def icon_color
    case @type
    when TYPE::SUCCESS
      "text-success"
    when TYPE::ERROR
      "text-danger"
    when TYPE::WARNING
      "text-warning"
    when TYPE::INFO
      "text-primary"
    else
      raise "Invalid toast type"
    end
  end
end
