require 'dcsv'

class Temporal
  attr_reader :start_time, :end_time
  def initialize(start_time, end_time)
    @start_time=start_time
    @end_time=end_time
  end

  #def encode(input)
  #  input.to_s.gsub(/([=;])/) { "\\#{$1}" }
  #end

  # takes an input hash or string and converts it
  # into the DCSV format. Returns a string.
  def to_dcsv
    hash = {}
    hash[:start] = start_time if start_time.present?
    hash[:end] = end_time if end_time.present?
    Dcsv.encode(hash)
  end

  def self.parse_temporal(temporal_rdf)
    temp = Dcsv.decode(temporal_rdf)
    Temporal.new(temp['start'], temp['end'])
  end

  def to_s
    if start_time.present? && end_time.present?
      "#{start_time} - #{end_time}"
    elsif start_time.present?
      start_time
    elsif end_time.present?
      end_time
    end
  end

  def convert_to_date(value)
    begin
      value.to_date.strftime("%Y-%m-%d")
    rescue NoMethodError
      value
    end
  end

end
