class WizardComponent < ViewComponent::Base
  Step = Struct.new(:title, :description, :desktop_video, :mobile_video)

  def initialize(id, steps:, current_step: 0)
    raise ArgumentError, "steps must be an array of at least one step." unless steps.is_a?(Array) && steps.size > 0

    @id = id
    @steps = steps
    @current_step = current_step
  end

  def current_step
    steps[@current_step]
  end

  def current_desktop_video_path
    "/videos/onboarding/#{current_step.desktop_video}"
  end

  def current_mobile_video_path
    "/videos/onboarding/#{current_step.mobile_video}"
  end

  def final_step?
    @current_step == steps.size - 1
  end

  def completed?(step)
    steps.index(step) < @current_step
  end

  def in_progress?(step)
    steps.index(step) == @current_step
  end

  def incomplete?(step)
    steps.index(step) > @current_step
  end

  def circle_styling(step)
    if completed?(step)
      "bg-primary hover:brightness-90"
    elsif in_progress?(step)
      "border-2 border-primary bg-white"
    else
      "border-2 border-gray-300 bg-white"
    end
  end

  def circle_text_styling(step)
    text_color = in_progress?(step) ? "text-primary" : "text-gray-500 invisible group-hover:visible"

    class_names(text_color, "hidden md:block absolute text-xs sm:text-sm font-medium top-9")
  end

  private

  attr_reader :id, :steps
end
