def FactoryGirl.create_citation(container_factory_name_or_object, user, attributes=nil, file = nil)
  citation = Citation.new
  citation.batch = curation_concern
  citation.resource_type = "Article"
  citation.apply_depositor_metadata(user.user_key)
  citation.creator = user.name
  citation.date_uploaded = Date.today
  Sufia::GenericFile::Actions.create_metadata(
      citation, user, curation_concern.pid
  )
  visibility ='private'
  citation.set_visibility(visibility)
  return citation
end
