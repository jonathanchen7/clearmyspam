module Dashboard
  class SenderDetailsComponent < ViewComponent::Base
    def initialize(sender, actionable_thread_count:, protected_thread_count:, last_email_date: nil)
      @sender = sender
      @actionable_thread_count = actionable_thread_count
      @protected_thread_count = protected_thread_count
      @last_email_date = last_email_date
    end
  end
end
