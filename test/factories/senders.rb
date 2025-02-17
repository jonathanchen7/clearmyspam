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
        email { Faker::Internet.email(domain: "mailchimp.com") }
      end
    end

    initialize_with do
      new(raw_sender, as_of_date: as_of_date)
    end
  end
end
