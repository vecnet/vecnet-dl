require "spatial.rb"
require "temporal.rb"
# This mixin adds the accessor fields and a before_save hook
# on a POST, the controller passes the attributes to the actor,
# which then sets these accessor methods. the hooks then copy and
# reformat the data into the time_period slot (which then formats the
# data into the form needed to be serialized to the RDF datastream).
#
# For display, the views call a helper routine to get the data and format it
module SpatialCoverage

  extend ActiveSupport::Concern

  included do
    before_save :format_spatials_from_lat_long, :format_temporals_from_start_time
    attr_accessor :longitude, :latitude
    attr_accessor :start_time
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


  def valid_temporal_data?
    !start_time.nil?
  end

  def format_temporals_from_start_time
    temp = []
    if valid_temporal_data?
      temp = start_time.map do |s|
        next if s.blank?
        Temporal.from_s(s)
      end.compact
    end
    self.time_periods = temp
  end

end
