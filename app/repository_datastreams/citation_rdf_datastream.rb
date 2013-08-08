class CitationRdfDatastream < ActiveFedora::NtriplesRDFDatastream
  map_predicates do |map|
    map.part_of(:to => "isPartOf", :in => RDF::DC)
    map.contributor(:in => RDF::DC) do |index|
      index.as :searchable, :displayable
    end
    map.creator(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.title(:in => RDF::DC) do |index|
      index.as :searchable, :displayable
    end
    map.description(:in => RDF::DC) do |index|
      index.type :text
      index.as :searchable, :displayable
    end
    map.publisher(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.date_created(:to => "created", :in => RDF::DC) do |index|
      index.as :searchable, :displayable
    end
    map.date_uploaded(:to => "dateSubmitted", :in => RDF::DC) do |index|
      index.type :date
      index.as :searchable, :displayable, :sortable
    end
    map.date_modified(:to => "modified", :in => RDF::DC) do |index|
      index.type :date
      index.as :searchable, :displayable, :sortable
    end
    map.subject(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.language(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.rights(:in => RDF::DC) do |index|
      index.as :searchable, :displayable
    end
    map.resource_type(:to => "type", :in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.identifier(:in => RDF::DC) do |index|
      index.as :searchable, :displayable
    end
    map.based_near(:in => RDF::FOAF) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.tag(:to => "relation", :in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.related_url(:to => "seeAlso", :in => RDF::RDFS)

    map.bibliographic_citation({in: RDF::DC, to: 'bibliographicCitation'})

    map.archived_object_type({in: RDF::RDFS, to: 'domain'}) do |index|
      index.as :searchable, :displayable, :facetable
    end
    map.references(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable
    end
  end
end
