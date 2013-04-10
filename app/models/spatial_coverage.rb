require "spatial.rb"
require "temporal.rb"
module SpatialCoverage

  extend ActiveSupport::Concern

  included do
    before_save :format_spatials_from_lat_long
    attr_accessor :longitude, :latitude, :start_time, :end_time
  end

  VALIDATIONS = [
      { :key => :spatial,
        :message => 'Invalid Spatial data, Latitude and Longitude must be of same length',
        :condition => lambda{ |gf| if (gf.longitude.present? && gf.latitude.present?)
                                     gf.latitude.length.eql?(gf.longitude.length)
                                   end
                            }
      },
      {:key => :temporal,
       :message => 'Invalid Temporal data, Start time and End time must be of same length',
       :condition => lambda{ |gf| if (gf.start_time.present? && gf.end_time.present?)
                                    gf.start_time.length.eql?(gf.end_time.length)
                                  end
       }}
  ]

  def data_validation(validation_hash)
    valid = true
    if !validation_hash[:condition].call(self)
      self.errors[validation_hash[:key]] ||= []
      self.errors[validation_hash[:key]] << validation_hash[:message]
      valid = false
    end
    return valid
  end

  def valid_spatial_data?
    return data_validation(VALIDATIONS.first)
  end


  def temporal_data
    return data_validation(VALIDATIONS.last)
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