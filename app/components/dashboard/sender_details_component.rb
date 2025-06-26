module Dashboard
  class SenderDetailsComponent < ViewComponent::Base
    def initialize(sender, last_email_date: nil)
      @sender = sender
      @last_email_date = last_email_date
    end
  end
end
