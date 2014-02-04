object curation_concern
attribute :noid=>:id
attribute :title
node(:id_with_version) do
"#{curation_concern.noid}/#{curation_concern.current_version_just_id}"  if curation_concern.respond_to?(:current_version_just_id)
end

node(:metadata) do
  result={}
  [:description, :depositor, :related_url, :based_near, :part_of, :creator,
   :contributor, :tag, :rights, :publisher, :date_created, :subject, :resource_type,
   :identifier, :language, :spatials, :temporals, :species,
   :bibliographic_citation, :archived_object_type, :references, :source,
   :alternative].each {|term|
          result[term] = curation_concern.send(term) if curation_concern.send(term).present?
        }
  result
end
