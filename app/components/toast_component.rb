class ToastComponent < ViewComponent::Base
  attr_accessor :title, :text
  attr_reader :type, :cta_action_type, :cta_text, :cta_stimulus_data

  module TYPE
    SUCCESS = "success"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"
  end

  module CTA_ACTION_TYPE
    CONFIRMATION = "confirmation"
    DESTRUCTIVE = "destructive"
  end

  def initialize(placeholder: false)
    @type = ToastComponent::TYPE::INFO
    @title = nil
    @text = nil
    @cta_action_type = ToastComponent::CTA_ACTION_TYPE::CONFIRMATION
    @cta_text = nil
    @cta_stimulus_data = nil
    @placeholder = placeholder
  end

  def info(title, text: nil)
    of_type(TYPE::INFO, title, text)
  end

  def success(title, text: nil)
    of_type(TYPE::SUCCESS, title, text)
  end

  def error(title, text: nil)
    of_type(TYPE::ERROR, title, text)
  end

  def with_confirm_cta(cta_text, stimulus_data:)
    with_cta(CTA_ACTION_TYPE::CONFIRMATION, cta_text, stimulus_data)
  end

  def with_destructive_cta(cta_text, stimulus_data:)
    with_cta(CTA_ACTION_TYPE::DESTRUCTIVE, cta_text, stimulus_data)
  end

  private

  def icon_name
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

  def cta_color
    case @cta_action_type
    when CTA_ACTION_TYPE::CONFIRMATION
      "text-primary"
    when CTA_ACTION_TYPE::DESTRUCTIVE
      "text-danger"
    else
      raise "Invalid CTA type"
    end
  end

  def of_type(type, title, text)
    @type = type
    @title = title
    @text = text if text.present?

    self
  end

  def with_cta(action_type, cta_text, stimulus_data)
    @cta_action_type = action_type
    @cta_text = cta_text
    @cta_stimulus_data = stimulus_data

    self
  end
end
