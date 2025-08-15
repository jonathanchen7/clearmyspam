module OnboardingHelper
  ONBOARDING_STEPS = [
    WizardComponent::Step.new(
      title: "Get Started",
      description: "Welcome to Clear My Spam! Let's take a quick tour.",
      desktop_video: "welcome_desktop.mp4",
      mobile_video: "welcome_mobile.mp4"
    ),
    WizardComponent::Step.new(
      title: "Details",
      description: "Select a sender to view or take actions on individual emails.",
      desktop_video: "details_desktop.mp4",
      mobile_video: "details_mobile.mp4"
    ),
    WizardComponent::Step.new(
      title: "Actions",
      description: "Delete or archive emails in bulk. Protect senders you want to keep.",
      desktop_video: "actions_desktop.mp4",
      mobile_video: "actions_mobile.mp4"
    ),
    WizardComponent::Step.new(
      title: "Options",
      description: "Choose your preferred way of tidying your inbox.",
      desktop_video: "options_desktop.mp4",
      mobile_video: "options_mobile.mp4"
    )
  ]
end
