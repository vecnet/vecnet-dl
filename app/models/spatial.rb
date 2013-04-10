
class Spatial
  attr_reader :latitude, :longitude
  def initialize(latitude, longitude)
    @latitude=latitude
    @longitude=longitude
  end

  def encode(input)
    input.to_s.gsub(/([=;])/) { "\\#{$1}" }
  end

  def encode_dcsv
    result = []
    hash={}
    hash[:north]=latitude if latitude.present?
    hash[:east]=longitude if longitude.present?
    Spatial.encode_dcsv(hash)
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

  def self.parse_spatial(spatial_rdf)
    temp=Spatial.decode(spatial_rdf)
    return Spatial.new(temp['north'],temp['east'])
  end


  def to_s
    if latitude.present? && longitude.present?
      return "(#{latitude}, #{longitude})"
    elsif latitude.present?
      return latitude
    elsif longitude.present?
      return longitude
    end
  end
end