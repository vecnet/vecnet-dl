class Temporal
  attr_reader :start_time, :end_time
  def initialize(start_time, end_time)
    @start_time=start_time
    @end_time=end_time
  end

  def encode(input)
    input.to_s.gsub(/([=;])/) { "\\#{$1}" }
  end

  # takes an input hash or string and converts it
  # into the DCSV format. Returns a string.
  def encode_dcsv
    hash={}
    hash[:start]=start_time if start_time.present?
    hash[:end]=end_time if end_time.present?
    Temporal.encode_dcsv(hash)
  end

  def self.encode_dcsv(input)
    if input.is_a?(Hash)
      result = []
      input.each_pair do |k,v|
        if k.is_a?(Integer)
          result << encode_dcsv(v)
        else
          result << "#{encode_dcsv(k)}=#{encode_dcsv(v)}"
        end
      end
      result.join(";")
    else
      input.to_s.gsub(/([=;])/) { "\\#{$1}" }
    end
  end

  def self.decode(str)
    result = {}
    unlabeled_count = 0
    value_list = str.split(/(?<!\\);/)
    value_list.each do |value|
      value.gsub!(/\\;/,';') # unescape ;
      label, rest = value.strip.split(/(?<!\\)=/,2)
      label.gsub!(/\\=/, '=')
      rest.gsub!(/\\=/, '=') if rest
      if rest
        result[label] = rest
      else
        result[unlabeled_count] = label
        unlabeled_count += 1
      end
    end
    result
  end

  def to_s
    if start_time.present? && end_time.present?
      return "#{start_time} - #{end_time}"
    elsif start_time.present?
      return start_time
    elsif end_time.present?
      return end_time
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