require "faker"

FactoryBot.define do
  factory :sender do
    transient do
      email { Faker::Internet.email }
      raw_sender { "#{Faker::Name.name} <#{email}>" }
    end

    as_of_date { Date.new(2023, 6, 24) }

    trait :personal do
      transient do
        email { Faker::Internet.email(domain: "gmail.com") }
      end
    end

    trait :business do
      transient do
        email { Sender::DUMMY_BUSINESS_SENDERS.keys.sample(random: Faker::Config.random) }
        name { Sender::DUMMY_BUSINESS_SENDERS[email] }
        raw_sender { "#{name} <#{email}>" }
      end

      before(:build) do |_sender, evaluator|
        unless Sender::DUMMY_BUSINESS_SENDERS.key?(evaluator.email)
          raise ArgumentError, "Invalid business email: #{evaluator.email}"
        end
      end
    end

    initialize_with do
      new(raw_sender, as_of_date: as_of_date)
    end
  end
end
