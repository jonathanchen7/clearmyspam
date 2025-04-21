# frozen_string_literal: true

class Sender
  PERSONAL_DOMAINS = %w[gmail.com yahoo.com hotmail.com outlook.com aol.com icloud.com].freeze

  EMAIL_REGEX = /([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,20})/
  FORMATTED_EMAIL_REGEX = /<#{EMAIL_REGEX.source}>/
  NAME_REGEX = /"?([^"]*)"? <.*>/

  attr_reader :email, :name, :as_of_date

  class << self
    def from_gmail_thread(gmail_thread)
      latest_message = gmail_thread.messages.first
      headers = latest_message.payload.headers
      raw_sender = Email.fetch_gmail_header(headers, "from")
      date = DateTime.parse(Email.fetch_gmail_header(headers, "date"))

      new(raw_sender, as_of_date: date)
    rescue => e
      Honeybadger.notify(e)
      nil
    end
  end

  def initialize(raw_sender, as_of_date:)
    @email = raw_sender[FORMATTED_EMAIL_REGEX, 1] || raw_sender[EMAIL_REGEX]
    raise ArgumentError, "Email could not be extracted from raw_sender #{raw_sender}" unless email

    @name = raw_sender[NAME_REGEX, 1] || email
    @as_of_date = as_of_date
  end

  def id
    hash.to_s
  end

  def domain
    @domain ||= email.split("@").last
  end

  def personal?
    PERSONAL_DOMAINS.include?(domain)
  end

  def newer_than?(other)
    raise ArgumentError, "Senders should have the same emails" unless email == other.email

    as_of_date > other.as_of_date
  end

  # #hash, #==, and #eql? are necessary for different instances of the same sender to be considered equal.
  def hash
    email.hash
  end

  def ==(other)
    email == other.email
  end

  def eql?(other)
    self == other
  end
end
