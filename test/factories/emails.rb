require "faker"

FactoryBot.define do
  factory :email do
    transient do
      sender_name { Faker::Name.name }
      sender_email { Faker::Internet.email }
      raw_sender { "#{sender_name} <#{sender_email}>" }
      date { Date.today }
    end

    vendor_id { SecureRandom.hex(16) }
    subject { Faker::Lorem.sentence }
    snippet { Faker::Lorem.paragraph }
    label_ids { ["INBOX"] }
    protected { false }

    trait :unread do
      label_ids { ["INBOX", "UNREAD"] }
    end

    trait :protected do
      protected { true }
    end

    trait :old do
      date { 1.year.ago }
    end

    trait :recent do
      date { 1.day.ago }
    end

    initialize_with do
      new(
        vendor_id: vendor_id,
        sender: Sender.new(raw_sender, as_of_date: date),
        date: date,
        subject: subject,
        snippet: snippet,
        label_ids: label_ids
      )
    end
  end
end
