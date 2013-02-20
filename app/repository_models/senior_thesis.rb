require 'datastreams/properties_datastream'
class SeniorThesis < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::RightsMetadata
  include Sufia::ModelMethods
  include Sufia::Noid
  include Sufia::GenericFile::Permissions

  has_metadata :name => "properties", :type => PropertiesDatastream
  has_metadata :name => "descMetadata", :type => SeniorThesisMetadataDatastream

  has_many :generic_files, :property => :is_part_of

  delegate_to :descMetadata, [:title, :created, :description], :unique => true
  delegate_to :properties, [:relative_path, :depositor], :unique => true
  delegate_to :descMetadata, [:contributor, :creator]

  def self.find_or_create(pid)
    begin
      @senior_thesis = SeniorThesis.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      @senior_thesis = SeniorThesis.create({pid: pid})
    end
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["noid_s"] = noid
    return solr_doc
  end

end