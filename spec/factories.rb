FactoryGirl.define do
  factory :project do
    title { "#{Faker::Lorem.word} #{Faker::Lorem.word} #{Faker::Lorem.word}" }
    description { "#{Faker::Lorem.paragraph} #{Faker::Lorem.paragraph}" }
    published true
    after(:create) {|instance|
    	10.times { FactoryGirl.create(:step, project_id: instance.id) }
    	steps = Step.where(:project_id => instance.id)
    	instance.steps = instance.steps << steps
    }
  end

  factory :step do
    name { "#{Faker::Lorem.word} #{Faker::Lorem.word} #{Faker::Lorem.word}" }
    description { "#{Faker::Lorem.paragraph} #{Faker::Lorem.paragraph}" }
  	sequence(:position)  { |n| (n-1)%10 }
  	ancestry 0
  	published_on { DateTime.now }
  	last false
  end

  factory :collection do
    name { "#{Faker::Lorem.word} #{Faker::Lorem.word} #{Faker::Lorem.word}" }
    description { "#{Faker::Lorem.paragraph} #{Faker::Lorem.paragraph}" }
    user_id 1
    published true
  end
end