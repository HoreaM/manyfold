FactoryBot.define do
  factory :link do
    url { Faker::Internet.url }
    text { Faker::Internet.username }
  end
end
