# frozen_string_literal: true

require "test_helper"

class SenderTest < ActiveSupport::TestCase
  test "#initialize sets as_of_date" do
    as_of_date = DateTime.now
    sender = Sender.new("<test@test.com>", as_of_date: as_of_date)
    assert_equal as_of_date, sender.as_of_date
  end

  test "#initialize extracts the email" do
    senders_to_email = {
      "Jonathan Chen <jonathanchen.dev@gmail.com>" => "jonathanchen.dev@gmail.com",
      "<jonathanchen.dev@gmail.com>" => "jonathanchen.dev@gmail.com",
      "jonathanchen.dev@gmail.com" => "jonathanchen.dev@gmail.com"
    }

    senders_to_email.each do |raw_sender, email|
      sender = Sender.new(raw_sender, as_of_date: nil)
      assert_equal email, sender.email
    end
  end

  test "#initialize extracts the name, defaulting to the email" do
    senders_to_name = {
      "Jonathan Chen <jonathanchen.dev@gmail.com>" => "Jonathan Chen",
      "<jonathanchen.dev@gmail.com>" => "jonathanchen.dev@gmail.com"
    }

    senders_to_name.each do |raw_sender, name|
      sender = Sender.new(raw_sender, as_of_date: nil)
      assert_equal name, sender.name
    end
  end

  test "#initialize raises an error if the email cannot be extracted" do
    invalid_senders = [
      "Jonathan Chen",
      "Jonathan Chen <>",
      "Jonathan Chen <@@@>",
      "Jonathan Chen <jonathan.com>",
      "Jonathan Chen <jonathan@>",
      "Jonathan Chen <@gmail.com>",
      "Jonathan Chen <jonathan@.com>",
      "Jonathan Chen <jonathan@com>",
      "Jonathan Chen <jonathan@com.>",
      "<@@@>"
    ]
    invalid_senders.each do |raw_sender|
      assert_raises(ArgumentError, "Email could not be extracted from raw_sender #{raw_sender}") do
        Sender.new(raw_sender, as_of_date: nil)
      end
    end
  end

  test "#domain returns the sender domain" do
    senders_to_domain = {
      "Jonathan Chen <jonathanchen.dev@gmail.com>" => "gmail.com",
      "Jonathan Chen <jonathanchen@crazydomain.org>" => "crazydomain.org"
    }

    senders_to_domain.each do |raw_sender, domain|
      sender = Sender.new(raw_sender, as_of_date: nil)
      assert_equal domain, sender.domain
    end
  end

  test "#personal? returns true if the domain is in the personal domains list" do
    personal_domains = %w[gmail.com yahoo.com hotmail.com outlook.com aol.com icloud.com]
    personal_domains.each do |domain|
      raw_sender = "Jonathan Chen <jonathanchen@#{domain}>"
      sender = Sender.new(raw_sender, as_of_date: nil)
      assert sender.personal?
    end

    bad_domains = %w[google.com crazydomain.org company.net test.co]
    bad_domains.each do |domain|
      raw_sender = "Jonathan Chen <jonathanchen@#{domain}>"
      sender = Sender.new(raw_sender, as_of_date: nil)
      assert_not sender.personal?
    end
  end

  test "#newer_than? raises an error if the emails are different" do
    sender1 = Sender.new("<jonathan@test.com>", as_of_date: nil)
    sender2 = Sender.new("<chen@test.com>", as_of_date: nil)

    assert_raises(ArgumentError) { sender1.newer_than?(sender2) }
    assert_raises(ArgumentError) { sender2.newer_than?(sender1) }
  end

  test "#newer_than? returns true iff the sender is newer than the other sender" do
    as_of_date = DateTime.new(2000, 5, 22)
    sender1 = Sender.new("Baby Jonathan <test@test.com>", as_of_date: as_of_date)
    sender2 = Sender.new("Old Jonathan <test@test.com>", as_of_date: as_of_date + 1.second)

    assert sender2.newer_than?(sender1)
  end
end
