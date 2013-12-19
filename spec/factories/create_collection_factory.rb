def FactoryGirl.create_collection(container_factory_name_or_object, user, attributes=nil, file = nil)
  collection = Collection.new
  collection.title="test"
  collection.save
  return collection
end
