def FactoryGirl.create_citation_file(container_factory_name_or_object, user, attributes, file = nil)
  curation_concern =
  if container_factory_name_or_object.is_a?(Symbol)
    FactoryGirl.create_curation_concern(container_factory_name_or_object, user)
  else
    container_factory_name_or_object
  end
  citation_file = CitationFile.new
  citation_file.batch = curation_concern
  citation_file.resource_type = "Endnote Citation"
  curation_concern.apply_depositor_metadata(user.user_key)
  curation_concern.creator = user.name
  curation_concern.date_uploaded = Date.today
  Sufia::GenericFile::Actions.create_metadata(
      citation_file, user, curation_concern.pid
  )
  citation_file.set_visibility(attributes[:visibility])
  if File.exist?(Rails.root.join('spec/support/files/HelloWorldSample.pdf'))
    file ||=File.new(Rails.root.join('spec/support/files/HelloWorldSample.pdf'))
    Sufia::GenericFile::Actions.create_content(
        citation_file,
        file,
        ::File.basename(file),
        'content',
        user
    )
    file.close
  end
  return citation_file
end
