require "spatial.rb"
require "temporal.rb"
module SpatialCoverage

  extend ActiveSupport::Concern

  included do
    validate :spatial_data, :if => lambda{ |object| object.latitude.present? && object.longitude.present? }
    validate :temporal_data,:if => lambda{ |object| object.start_time.present? && object.end_time.present? }
    before_save :format_spatials_from_lat_long, :format_temporals_from_start_end_time
    attr_accessor :longitude, :latitude, :start_time, :end_time
  end

  VALIDATIONS = [
      {:key => :spatial, :message => 'Invalid Spatial data, Latitude and Longitude must be of same length', :condition => lambda { |obj| !obj.latitude.length.eql?(obj.longitude.length)}},
      {:key => :temporal, :message => 'Invalid Temporal data, Start time and End time must be of same length', :condition => lambda { |obj| !obj.start_time.length.eql?(obj.end_time.length)}}
  ]

  def data_validation(validation_hash)
    valid = true
    if validation_hash[:condition].call(self)
      self.errors[validation_hash[:key]] ||= []
      self.errors[validation_hash[:key]] << validation_hash[:message]
      valid = false
    end
    return valid
  end

  def spatial_data
    return data_validation(VALIDATIONS.first)
  end


  def temporal_data
    return data_validation(VALIDATIONS.last)
  end

  def format_spatials_from_lat_long
    if latitude.present? && longitude.present?
      temp=[]
      latitude.each_with_index do |lat, i|
        temp<< Spatial.new(lat, longitude[i]).encode_dcsv
      end
      self.spatials=temp
      return temp
    end
  end

  def format_temporals_from_start_end_time
    if start_time.present? && end_time.present?
      temp=[]
      start_time.each_with_index do |start_time, i|
        temp<< Temporal.new(start_time, end_time[i]).encode_dcsv
      end
      self.temporals=temp
      return temp
    end
  end

end