require Sufia::Engine.root.join('app/models/datastreams/generic_file_rdf_datastream')
class GenericFileRdfDatastream
  map_predicates do |map|
    map.spatials(:to => "spatial", :in => RDF::DC)
    map.temporals(:to => "temporal", :in => RDF::DC)
  end
end