require "spatial.rb"
require "temporal.rb"
module SpatialCoverage

  extend ActiveSupport::Concern

  included do
    before_save :format_spatials_from_lat_long
    attr_accessor :longitude, :latitude, :start_time, :end_time
    validates_with SpatialValidator
  end

  def valid_spatial_data?
    return !latitude.blank? && !longitude.blank? && self.valid?
  end

  def valid_temporal_data?
    return !start_time.blank? && !end_time.blank? && self.valid?
  end

  def format_spatials_from_lat_long
    temp=[]
    if valid_spatial_data?
      latitude.each_with_index do |lat, i|
        temp<< Spatial.new(lat, longitude[i]).encode_dcsv
      end
    end
    self.spatials=temp
  end

  def format_temporals_from_start_end_time
    if valid_temporal_data?
      temp=[]
      start_time.each_with_index do |start_time, i|
        temp<< Temporal.new(start_time, end_time[i]).encode_dcsv
      end
      self.temporals=temp
      return temp
    end
  end

end