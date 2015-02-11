require "temporal.rb"
# This mixin adds the accessor fields and a before_save hook
# on a POST, the controller passes the attributes to the actor,
# which then sets these accessor methods. the hooks then copy and
# reformat the data into the time_period slot (which then formats the
# data into the form needed to be serialized to the RDF datastream).
#
# For display, the views call a helper routine to get the data and format it
module TemporalMixin

  extend ActiveSupport::Concern

  included do
    before_save :format_temporals_from_start_time
    attr_accessor :start_time
  end

  # There are two ways to interact with the time period metadata.
  #
  # First, one can get a list of Temporal objects. use `time_periods` to do that
  #
  # Second, one can get and save strings encoding time periods. Use
  # `temporal` for that (this name is BAD. please refactor). These are not
  # the stored dcsv strings. These are a human readable form of the ranges.
  #
  # The `start_time` field is used to save form data into the object. a hook
  # is used to copy it into the descMetadata on save.
  def time_periods
    Array(self.datastreams["descMetadata"].temporals).map do |dscv_s|
      Temporal.from_dcsv(dscv_s)
    end
  end

  def time_periods=(temporal_array)
    self.datastreams["descMetadata"].temporals = temporal_array.map do |t|
      t.to_dcsv
    end
  end

  def temporal
    time_periods.map(&:to_s)
  end

  def temporal=(date_array)
    return if date_array.nil?
    time_periods = start_time.map { |s| Temporal.from_s(s) }.compact
  end

  def format_temporals_from_start_time
    unless start_time.nil?
      self.time_periods = start_time.map { |s| Temporal.from_s(s) }.compact
    end
  end
end
