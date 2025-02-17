class OnboardingController < AuthenticatedController
  rate_limit to: 20, within: 1.minute, by: -> { current_user.id }

  def step
    new_step = params.require(:step).to_i
    if new_step < 0
      new_step = 0
    elsif new_step >= OnboardingHelper::ONBOARDING_STEPS.size
      new_step = OnboardingHelper::ONBOARDING_STEPS.size - 1
    end

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("onboarding_wizard", WizardComponent.new(
            "onboarding",
            steps: OnboardingHelper::ONBOARDING_STEPS,
            current_step: new_step
          ))
        ]
      end
    end
  end

  def complete
    current_user.update!(onboarding_completed_at: Time.current)

    respond_to do |format|
      format.json { render json: { success: true } }
      format.turbo_stream do
        render turbo_stream: [turbo_stream.remove("onboarding_wizard")]
      end
    end
  end
end
