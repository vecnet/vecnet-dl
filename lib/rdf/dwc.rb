module RDF
  ##
  # Dublin Core (DC) vocabulary.
  #
  # @see http://dublincore.org/schemas/rdfs/
  class DWC < Vocabulary("http://rs.tdwg.org/dwc/terms/")
    property :basisOfRecord
    property :scientificName
    property :nameAccordingToID
    property :taxonID
  end
end
