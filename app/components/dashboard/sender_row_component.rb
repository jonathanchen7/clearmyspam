# frozen_string_literal: true

module Dashboard
  class SenderRowComponent < ViewComponent::Base
    attr_reader :sender, :sender_emails

    def initialize(sender, sender_emails:, final_page_fetched:)
      @sender = sender
      @sender_emails = sender_emails
      @final_page_fetched = final_page_fetched
    end

    def actionable_thread_count
      sender_emails.select(&:actionable?).count
    end

    def protected_thread_count
      sender_emails.select(&:protected?).count
    end

    def last_email_date
      time_ago_in_words(sender_emails.map(&:date).max)
    end
  end
end
