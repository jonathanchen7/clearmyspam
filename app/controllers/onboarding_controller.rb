class OnboardingController < AuthenticatedController
  set_rate_limit to: 20

  def step
    new_step = params.require(:step).to_i

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("onboarding_wizard", WizardComponent.new(
            "onboarding",
            steps: OnboardingHelper::ONBOARDING_STEPS,
            current_step: new_step.clamp(0, OnboardingHelper::ONBOARDING_STEPS.size - 1)
          ))
        ]
      end
    end
  end

  def complete
    current_user.update!(onboarding_completed_at: Time.current)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [turbo_stream.remove("onboarding_wizard")]
      end
    end
  end
end
