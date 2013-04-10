require_relative '../repository_datastreams/generic_file_rdf_datastream'
require_relative '../repository_datastreams/file_content_datastream.rb'
require Sufia::Engine.root.join('app/models/generic_file')
class GenericFile
  include CurationConcern::ModelMethods
  include SpatialCoverage

  belongs_to :batch, property: :is_part_of, class_name: 'ActiveFedora::Base'

  validates :batch, presence: true
  validates :file, presence: true, on: :create

  attr_accessor :file, :version, :visibility

  def spatials
     return Array(self.datastreams["descMetadata"].spatials).collect{|spatial| Spatial.parse_spatial(spatial)}
  end

  def temporals
     puts "get temporals decode them"
     temporals= self.datastreams["descMetadata"].temporals.collect.each{ |temporal| Temporal.decode(temporal) }
     puts "Temporals: #{temporals.inspect}"
     temp=[]
     temporals.each{ |temporal_hash| temp<<Temporal.new(temporal_hash["start"],temporal_hash["end"])}
     return temp
  end

  def spatials=(formated_str)
      self.datastreams["descMetadata"].spatials=formated_str
  end

  def filename
    content.label
  end

  def to_s
    title || label || "No Title"
  end

  def versions
    content.versions
  end

  def current_version_id
    content.latest_version.versionID
  end

  def human_readable_type
    self.class.to_s.demodulize.titleize
  end
end

