require "spatial.rb"
module SpatialCoverage

  extend ActiveSupport::Concern

  included do
    before_save :format_spatials_from_lat_long
    attr_accessor :longitude, :latitude
    validates_with SpatialValidator
  end

  def valid_spatial_data?
    !latitude.blank? && !longitude.blank? && self.valid?
  end

  def format_spatials_from_lat_long
    temp = []
    if valid_spatial_data?
      latitude.each_with_index do |lat, i|
        temp << Spatial.new(lat, longitude[i]).to_dcsv
      end
    end
    self.spatials = temp
  end
end
