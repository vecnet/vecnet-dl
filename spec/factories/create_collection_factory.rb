def FactoryGirl.create_collection(pid, user, attributes=nil, file = nil)
  pid = pid || CurationConcern.mint_a_pid
  collection = Collection.new(pid: pid)
  collection.apply_depositor_metadata(user.user_key)
  collection.creator = user.name
  collection.save
  return collection
end
