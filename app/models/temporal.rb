require 'dcsv'

class Temporal
  attr_reader :start_time, :end_time
  def initialize(start_time, end_time)
    @start_time = start_time
    @end_time = end_time
  end

  # takes an input hash or string and converts it
  # into the DCSV format. Returns a string.
  def to_dcsv
    hash = {}
    hash[:start] = start_time if start_time.present?
    hash[:end] = end_time if end_time.present?
    Dcsv.encode(hash)
  end

  def self.from_dcsv(temporal_rdf)
    temp = Dcsv.decode(temporal_rdf)
    Temporal.new(temp['start'], temp['end'])
  end

  def to_s
    if start_time.present? && end_time.present?
      if start_time == end_time
        "#{start_time}"
      else
        "#{start_time} -- #{end_time}"
      end
    elsif start_time.present?
      "#{start_time} --"
    elsif end_time.present?
      "-- #{end_time}"
    else
      ""
    end
  end

  # if s has the form
  # YYYY(-MM(-DD)?)? (--? (YYYY(-MM(-DD)?)?)?)?
  # or
  # - YYYY(-MM(-DD)?)?
  # returns a Temporal
  # otherwise returns nil
  #
  # This does not check that any months given are in the range 01-12
  # nor that any days are in the range 01-31.
  # But it could do those checks. I don't think it will be an issue?
  # Maybe if we wish to admit geoname ids as allowable locations for
  # the endnote ingest.
  #
  # Subtle. Ensure the string 2010-2011 is not matched as the 11th
  # of the 20th month of 2010.
  def self.from_s(s)
    m = /\A\s*
      (\d{4}  # start year
        (-\d{1,2})? # month
        (-\d{1,2})? # day
      )\s*
      (--?\s*
        (\d{4} # end year
          (-\d{1,2})? # month
          (-\d{1,2})? # day
        )?
      )?\Z/x.match(s)
    if m.nil?
      m = /\A\s*--?\s*
        (\d{4} # end year
          (-\d{1,2})? # month
          (-\d{1,2})? # day
        )\Z/x.match(s)
      return nil if m.nil?
      start_time = nil
      end_time = m[1]
    else
      start_time = m[1]
      hyphen = m[4]
      end_time = m[5]
    end
    if start_time.nil?
      # only a hyphen and an end time
      Temporal.new(nil, end_time)
    elsif hyphen.nil?
      # only a start time. interpret as a single year or month or date
      Temporal.new(start_time, start_time)
    elsif end_time.nil?
      # a hyphen but no end time
      Temporal.new(start_time, nil)
    else
      # a start and end time
      Temporal.new(start_time, end_time)
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
