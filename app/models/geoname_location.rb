module GeonameLocation

  extend ActiveSupport::Concern

  included do
    #before_save :format_based_near_from_location
    attr_accessor :geoname_locations
  end

  class Location
    attr_reader :name, :geoname_id
    def initialize(name, geoname_id)
      @name=name
      @geoname_id=geoname_id
    end

    def escape_string(input)
      input.to_s.gsub(/([=;])/) { "\\#{$1}" }
    end

    def encode
      result = []
      hash={}
      hash[:name]=name if name.present?
      hash[:geoname_id]=geoname_id.present? ? geoname_id : ""
      Location.encode(hash)
    end

    def self.encode_location(input)
      if input.is_a?(Hash)
        result = []
        input.each_pair do |k,v|
          if k.is_a?(Integer)
            result << encode_location(v)
          else
            result << "#{encode_location(k)}=#{encode_location(v)}"
          end
        end
        result.join(";")
      else
        escape_string(input)
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

    def self.parse_location(location_rdf)
      temp=Location.decode(location_rdf)
      return Location.new(temp['geoname_id'],temp['name'])
    end


    def to_s
      if name.present? && geoname_id.present?
        return "(Name:#{name}, geoname_id:#{geoname_id})"
      elsif name.present?
        return "Name:#{name}"
      elsif geoname_id.present?
        return "geoname_id:#{geoname_id}"
      end
    end
  end

  def get_valid_locations
    self.geoname_locations.reject!{|l| !self.based_near.include?l.split('|').first}
  end

  def format_based_near_from_location
    puts "Location array: #{self.geoname_locations}"
    temp=[]
    locations=get_valid_locations
    locations.each do |location_with_id|
      test=location_with_id.spilt('|')
      encoded_location= test.count==2 ? Location.new(test.first, test.last).encode_location : Location.new(test.first, nil).encode_location
      temp<<encoded_location
    end
    self.based_near=temp
    return temp
  end
end