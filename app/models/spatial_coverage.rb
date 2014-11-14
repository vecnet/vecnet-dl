require "spatial.rb"
require "temporal.rb"
module SpatialCoverage

  extend ActiveSupport::Concern

  included do
    before_save :format_spatials_from_lat_long, :format_temporals_from_start_end_time
    attr_accessor :longitude, :latitude, :start_time, :end_time
    validates_with SpatialValidator
    validates_with TemporalValidator
  end

  def valid_spatial_data?
    !latitude.blank? && !longitude.blank? && self.valid?
  end

  def valid_temporal_data?
    !start_time.nil? && !end_time.nil? && self.valid?
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

  def format_temporals_from_start_end_time
    temp = []
    if valid_temporal_data?
      start_time.each_with_index do |start_time, i|
        temp << Temporal.new(start_time, end_time[i]).to_dcsv
      end
    end
    self.temporals = temp
  end

end
