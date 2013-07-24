require File.expand_path("../../repository_datastreams/batch_rdf_datastream", __FILE__)
class Collection < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::RightsMetadata
  include Sufia::ModelMethods
  include CurationConcern::ModelMethods
  include Sufia::Noid


  has_metadata name: "descMetadata", type: BatchRdfDatastream

  belongs_to :user, :property => "creator"
  has_many :generic_files, :property => :is_part_of

  delegate :title, :to => :descMetadata
  delegate :creator, :to => :descMetadata
  delegate :part, :to => :descMetadata
  delegate :status, :to => :descMetadata
  delegate :archived_object_type, :to => :descMetadata

  before_save {|obj| obj.archived_object_type = self.class.to_s }

  def human_readable_type
    self.class.to_s.demodulize.titleize
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["noid_s"] = noid
    return solr_doc
  end

   def to_param
    noid
  end

end
