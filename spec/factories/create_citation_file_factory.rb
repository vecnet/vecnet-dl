def FactoryGirl.create_citation_file(container_factory_name_or_object, user, attributes=nil, file = nil)
  curation_concern =
  if container_factory_name_or_object.is_a?(Symbol)
    FactoryGirl.create_curation_concern(container_factory_name_or_object, user)
  else
    container_factory_name_or_object
  end
  citation_file = CitationFile.new
  citation_file.batch = curation_concern
  citation_file.resource_type = "Endnote Citation"
  citation_file.apply_depositor_metadata(user.user_key)
  citation_file.creator = user.name
  citation_file.date_uploaded = Date.today
  if File.exist?(Rails.root.join('spec/support/files/HelloWorldSample.pdf'))
    file ||=File.new(Rails.root.join('spec/support/files/HelloWorldSample.pdf'))
    citation_file.file=file
    Sufia::GenericFile::Actions.create_content(
        citation_file,
        citation_file.file,
        ::File.basename(citation_file.file),
        'content',
        user
    )
    file.close
  end
  Sufia::GenericFile::Actions.create_metadata(
      citation_file, user, curation_concern.pid
  )
  visibility ='private'
  citation_file.set_visibility(visibility)
  return citation_file
end
