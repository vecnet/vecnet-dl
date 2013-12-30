FactoryGirl.define do
  factory :citation, class: Citation do
    sequence(:title) {|n| "Title #{n}"}
    rights { Sufia::Engine.config.cc_licenses.keys.first }
  end
end
