class Geoname < ActiveRecord::Base
  has_many :geoname_hierarchies , :foreign_key => "geoname_id"
  has_many :cache_geoname_searches , :foreign_key => "geoname_id"

  self.primary_key = 'geonameid'
  self.table_name = 'geoname'

end