# frozen_string_literal: true

module Gmail
  class SenderParser
    attr_reader :sender

    SENDER_EMAIL_REGEX = /<(.*@.*)>/
    SENDER_NAME_REGEX = /"?([^"]*)"? <.*>/

    def initialize(sender)
      @sender = sender
    end

    def email
      @email ||= sender[SENDER_EMAIL_REGEX, 1] || sender
    end

    def sender_name
      @sender_name ||= sender[SENDER_NAME_REGEX, 1] || email
    end

    def sender_domain
      @sender_domain ||= email.split("@").last
    end
  end
end
