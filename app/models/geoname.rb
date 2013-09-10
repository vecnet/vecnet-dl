class Geoname < ActiveRecord::Base
  has_many :location_tree_Structures , :foreign_key => "geoname_id"
  has_many :geoname_details , :foreign_key => "geoname_id"

  self.primary_key = 'geonameid'
  self.table_name = 'geoname'

end