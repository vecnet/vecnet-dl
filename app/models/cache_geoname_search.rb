class CacheGeonameSearch < ActiveRecord::Base
  self.table_name = 'geoname_search'
  belongs_to :geoname , :foreign_key => "geoname_id"

  attr_accessible :geoname_id, :location, :object_id

  def self.find_or_create(location,geoname_id)
    if CacheGeonameSearch.find_by_geonameid(geoname_id).nil?
      return CacheGeonameSearch.create_from_attributes(location,geoname_id)
    else
      return CacheGeonameSearch.update_from_attributes(location,geoname_id)
    end
  end

  def self.create_from_attributes(location,geoname_id,pid=nil)
    cache = CacheGeonameSearch.new(geonameid: geoname_id,
                                     location: location,
                                     object_id:pid)
    cache.save!
    cache
  end

  def self.update_from_attributes(location,geoname_id,pid=nil)
    cache = CacheGeonameSearch.find_by_location(location)
    unless cache.geoname_id == geoname_id
      cache.update_attributes!(geoname_id: geoname_id)
      cache.save!
    end
    cache
  end

end