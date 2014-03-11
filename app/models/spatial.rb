require 'dcsv'

class Spatial
  attr_reader :latitude, :longitude
  def initialize(latitude, longitude)
    @latitude=latitude
    @longitude=longitude
  end

  #def encode(input)
  #  input.to_s.gsub(/([=;])/) { "\\#{$1}" }
  #end

  def to_dcsv
    hash = {}
    hash[:north] = latitude if latitude.present?
    hash[:east] = longitude if longitude.present?
    Dcsv.encode(hash)
  end

  def self.parse_spatial(spatial_rdf)
    temp = Dcsv.decode(spatial_rdf)
    return Spatial.new(temp['north'],temp['east'])
  end


  def to_s
    if latitude.present? && longitude.present?
      return "(#{latitude}, #{longitude})"
    elsif latitude.present?
      return latitude
    elsif longitude.present?
      return longitude
    end
  end
end
