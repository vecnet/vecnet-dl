require Sufia::Models::Engine.root.join('app/models/datastreams/generic_file_rdf_datastream')
require File.expand_path('../../../lib/rdf/dwc', __FILE__)
class GenericFileRdfDatastream
  map_predicates do |map|
    map.spatials(:to => "spatial", :in => RDF::DC)
    map.temporals(:to => "temporal", :in => RDF::DC)
    map.species(:to => "scientificName", :in => RDF::DWC) do |index|
      index.as :searchable, :facetable, :displayable
    end
  end
end