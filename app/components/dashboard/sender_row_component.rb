# frozen_string_literal: true

module Dashboard
  class SenderRowComponent < ViewComponent::Base
    attr_reader :sender

    def initialize(sender)
      @sender = sender
    end

    def last_email_date
      time_ago_in_words(@sender.as_of_date)
    end
  end
end
