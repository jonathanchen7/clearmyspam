module OnboardingHelper
  ONBOARDING_STEPS = [
    WizardComponent::Step.new(
      title: "Get Started",
      description: "Welcome to Clear My Spam! Let's take a quick tour.",
      desktop_image: "desktop_mockup.png",
      mobile_image: "onboarding/welcome_mobile.png"
    ),
    WizardComponent::Step.new(
      title: "Loading Emails",
      description: "Your first #{Rails.configuration.sync_fetch_count} emails are grouped by sender. Use \"Load more\" to fetch additional emails.",
      desktop_image: "onboarding/loading_desktop.webp",
      mobile_image: "onboarding/loading_mobile.webp"
    ),
    WizardComponent::Step.new(
      title: "Actions",
      description: "Delete or archive emails in bulk. Protect emails that you want to keep.",
      desktop_image: "onboarding/actions_desktop.webp",
      mobile_image: "onboarding/actions_mobile.webp"
    ),
    WizardComponent::Step.new(
      title: "Details",
      description: "Select a sender to view their emails. Here, you can load more emails or unsubscribe from future emails.",
      desktop_image: "onboarding/details_desktop.webp",
      mobile_image: "onboarding/details_mobile.webp"
    ),
    WizardComponent::Step.new(
      title: "Options",
      description: "Choose your preferred way of tidying your inbox.",
      desktop_image: "onboarding/options_desktop.webp",
      mobile_image: "onboarding/options_mobile.webp"
    )
  ]
end
