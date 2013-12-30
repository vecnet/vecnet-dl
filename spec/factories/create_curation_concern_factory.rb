def FactoryGirl.create_curation_concern(factory_name, user, override_attributes = {})
  pid = CurationConcern.mint_a_pid
  curation_concern = factory_name.to_s.classify.constantize.new(pid: pid)
  puts "factory_name: #{factory_name}, test:#{factory_name.to_s.classify.constantize}, pid: #{pid}, Curationconcern: #{curation_concern.inspect}"
  attributes = override_attributes.reverse_merge(FactoryGirl.attributes_for(factory_name))
  actor = CurationConcern.actor(curation_concern, user, attributes)
  actor.create!
  curation_concern
end