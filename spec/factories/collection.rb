FactoryGirl.define do
  factory :collection, class: Collection do
    ignore do
      pid "vecnet:fixture-collection"
    end
    initialize_with { new(pid: pid) }
    before(:create) do |gf|
      gf.apply_depositor_metadata "testuser"
      gf.inner_object.pid = "vecnet:fixture-collection"
      gf.label = "collection object"
    end
    read_groups ["public"]
  end
end
