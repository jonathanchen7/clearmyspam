# frozen_string_literal: true

require "digest"

class Sender
  DUMMY_BUSINESS_SENDERS = {
    "info@google.com" => "Google",
    "marketing@stripe.com" => "Stripe",
    "newsletter@amazon.com" => "Amazon",
    "updates@apple.com" => "Apple",
    "hello@meta.com" => "Meta",
    "sales@salesforce.com" => "Salesforce",
    "press@netflix.com" => "Netflix",
    "hello@openai.com" => "OpenAI",
    "offers@ubereats.com" => "Uber Eats",
    "news@nytimes.com" => "NYTimes",
    "deals@bestbuy.com" => "Best Buy",
    "promotions@airbnb.com" => "Airbnb",
    "team@slack.com" => "Slack",
    "updates@github.com" => "GitHub",
    "hello@notion.so" => "Notion",
    "marketing@dropbox.com" => "Dropbox",
    "contact@zoom.us" => "Zoom",
    "info@shopify.com" => "Shopify",
    "finance@adobe.com" => "Adobe",
    "hello@figma.com" => "Figma",
    "info@doordash.com" => "DoorDash",
    "newsletter@robinhood.com" => "Robinhood",
    "support@spotify.com" => "Spotify",
    "hello@asana.com" => "Asana",
    "updates@linkedin.com" => "LinkedIn",
    "news@bloomberg.com" => "Bloomberg",
    "offers@expedia.com" => "Expedia",
    "hello@canva.com" => "Canva",
    "promotions@hulu.com" => "Hulu",
    "info@twilio.com" => "Twilio"
  }.freeze
  PERSONAL_DOMAINS = %w[gmail.com yahoo.com hotmail.com outlook.com aol.com icloud.com].freeze

  EMAIL_REGEX = /([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,20})/
  FORMATTED_EMAIL_REGEX = /<#{EMAIL_REGEX.source}>/
  NAME_REGEX = /"?([^"]*)"? <.*>/

  attr_accessor :email_count, :protected
  attr_reader :email, :name, :as_of_date, :raw_sender

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

    def protect_all!(user, sender_ids)
      user.protected_senders.upsert_all(sender_ids.map { |sender_id| { sender_id: } }, unique_by: %i[user_id sender_id])
    end

    def unprotect_all!(user, sender_ids)
      user.protected_senders.where(sender_id: sender_ids).delete_all
    end
  end

  def initialize(raw_sender, as_of_date:)
    @email = raw_sender[FORMATTED_EMAIL_REGEX, 1] || raw_sender[EMAIL_REGEX]
    raise ArgumentError, "Email could not be extracted from raw_sender #{raw_sender}" unless email

    @name = raw_sender[NAME_REGEX, 1] || email
    @as_of_date = as_of_date
    @raw_sender = raw_sender
  end

  def id
    @id ||= Digest::MD5.hexdigest(email)
  end

  def get_email_count!(user)
    @email_count = Gmail::Client.new(user).get_thread_count!(query: query_string)
  end

  def list_emails!(user, max_results: Rails.configuration.sender_dispose_all_max)
    Gmail::Client.new(user).list_emails!(query: query_string, max_results:)
  end

  def fetch_actionable_email_ids!(user)
    email_ids, _page_token = list_emails!(user)
    actionable_email_ids = ProtectedEmail.actionable_email_ids(user, email_ids)
    actionable_email_ids = actionable_email_ids.first(user.remaining_disposal_count) if user.unpaid?

    actionable_email_ids
  rescue => e
    Honeybadger.notify(e)
    []
  end

  def fetch_emails!(user, inbox, page: 1)
    page_token = page == 1 ? nil : inbox.page_tokens.for(sender_id: id, page: page - 1)
    emails, next_page_token = Gmail::Client.new(user).get_emails!(query: query_string, page_token: page_token)
    inbox.page_tokens.add(next_page_token, sender_id: id)

    emails.sort
  end

  def query_string
    "from:#{email}"
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

  private

  def <=>(other)
    other.email_count <=> email_count
  end

  # #hash, #==, and #eql? are necessary for different instances of the same sender to be considered equal.
  def hash
    email.hash
  end

  def ==(other)
    id == other.id
  end

  def eql?(other)
    self == other
  end
end
