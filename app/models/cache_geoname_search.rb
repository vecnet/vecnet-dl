class CacheGeonameSearch < ActiveRecord::Base
  self.table_name = 'geoname_search'
  belongs_to :geoname , :foreign_key => "geoname_id"

  attr_accessible :geoname_id, :geo_location, :object_id

  def self.find_or_create(location,geoname_id)
    cache = CacheGeonameSearch.find_by_geo_location(location)
    if cache.nil?
      cache = CacheGeonameSearch.create_from_attributes(location, geoname_id)
    elsif cache.geoname_id != geoname_id
      cache.update_attributes!(geoname_id: geoname_id)
      cache.save!
    end
    cache
  end

  def self.create_from_attributes(location,geoname_id,pid=nil)
    cache = CacheGeonameSearch.new(geoname_id: geoname_id,
                                   geo_location: location,
                                   object_id: pid)
    cache.save!
    cache
  end

end
