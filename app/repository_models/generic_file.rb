require Sufia::Engine.root.join('app/models/generic_file')
class GenericFile
  include SpatialCoverage

  belongs_to :batch, property: :is_part_of, class_name: 'ActiveFedora::Base'

  validates :batch, presence: true
  validates :file, presence: true, on: :create

  attr_accessor :file, :version, :visibility

  delegate_to :descMetadata, [:spatials, :temporals]

  def spatials
    spatials= self.datastreams["descMetadata"].spatials.collect.each {|spatial| Spatial.decode(spatial)}
    temp=[]
    spatials.each{ |spatial_hash| temp<<Spatial.new(spatial_hash["north"],spatial_hash["east"])}
    return temp
  end

  def temporals
    puts "get temporals decode them"
    temporals= self.datastreams["descMetadata"].temporals.collect.each{ |temporal| Temporal.decode(temporal) }
    puts "Temporals: #{temporals.inspect}"
    temp=[]
    temporals.each{ |temporal_hash| temp<<Temporal.new(temporal_hash["start"],temporal_hash["end"])}
    return temp
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
