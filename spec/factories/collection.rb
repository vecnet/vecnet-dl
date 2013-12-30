FactoryGirl.define do
  factory :collection, class: Collection do
    sequence(:title) {|n| "Title #{n}"}
  end
end
