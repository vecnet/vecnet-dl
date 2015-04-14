xml.metadata("xmlns:dc" => "http://purl.org/dc/elements/1.1/",
             "xmlns:dcterms" => "http://purl.org/dc/terms/",
             "xmlns:dwc" => "http://rs.tdwg.org/dwc/terms/",
             "xmlns:vn" => "https://dl.vecnet.org/terms#") do

  xml.tag!("vn:identifier", curation_concern.noid)
  xml.tag!("vn:content_version", curation_concern.current_version_just_id)
  tag_each(xml, "dc:identifier", curation_concern.identifier)
  xml.tag!("vn:model", curation_concern.class)
  xml.tag!("vn:purl", curation_concern.persistent_url)

  xml.tag!("vn:depositor", curation_concern.depositor)
  xml.tag!("dc:date_uploaded", curation_concern.date_uploaded)
  xml.tag!("dc:date_modified", curation_concern.date_modified)
  xml.tag!("vn:thumbnail", download_url(curation_concern.thumbnail_noid, {datastream_id: 'thumbnail'})) if curation_concern.thumbnail_noid

  xml.tag!("dc:title", curation_concern.title)

  tag_each(xml, "dc:description", curation_concern.description)
  tag_each(xml, "dc:coverage", curation_concern.based_near)
  tag_each(xml, "dc:creator", curation_concern.creator)
  tag_each(xml, "dc:contributor", curation_concern.contributor)
  tag_each(xml, "dc:relation", curation_concern.tag)
  tag_each(xml, "dc:subject", curation_concern.subject)
  tag_each(xml, "dc:rights", curation_concern.rights)
  tag_each(xml, "dc:publisher", curation_concern.publisher)
  tag_each(xml, "dc:date_created", curation_concern.date_created)
  tag_each(xml, "dc:related", curation_concern.related_url)
  tag_each(xml, "dc:language", curation_concern.language)
  tag_each(xml, "dc:spatial", curation_concern.spatials)
  tag_each(xml, "dc:temporal", curation_concern.temporal)
  tag_each(xml, "dc:type", curation_concern.resource_type)
  tag_each(xml, "dwc:scientificName", curation_concern.species)
  tag_each(xml, "vn:schema_version", curation_concern.conforms_to)

  tag_each(xml, "dc:access.read.group", curation_concern.read_groups)
  tag_each(xml, "dc:access.read.person", curation_concern.read_users)
  tag_each(xml, "dc:access.edit.group", curation_concern.edit_groups)
  tag_each(xml, "dc:access.edit.person", curation_concern.edit_users)

  tag_each(xml, "dc:format", curation_concern.mime_type)
  xml.tag!("vn:filename", curation_concern.filename)

  tag_each(xml, "vn:related_files", curation_concern.related_files.map { |gf| gf.noid })

  full_text = curation_concern.get_full_text
  xml.tag!("full_text", full_text) if full_text
end
