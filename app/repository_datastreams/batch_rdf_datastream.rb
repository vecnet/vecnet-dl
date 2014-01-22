require Sufia::Models::Engine.root.join('app/models/datastreams/batch_rdf_datastream')
class BatchRdfDatastream
  map_predicates do |map|
    map.archived_object_type({in: RDF::DC, to: 'type'}) do |index|
      index.as :searchable, :displayable, :facetable
    end
  end
end