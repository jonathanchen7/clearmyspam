module Dashboard
  class SenderDetailsComponent < ViewComponent::Base
    def initialize(sender, email_count:, last_email_date: nil)
      @sender = sender
      @email_count = email_count
      @last_email_date = last_email_date
    end
  end
end
