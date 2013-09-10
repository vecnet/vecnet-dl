class GeonameHierarchy < ActiveRecord::Base
  self.table_name = 'geonamehierarchy'
  self.primary_key = 'hierarchyid'

  attr_accessible :geonameid, :hierarchytree, :hierarchytreetopnoamy
  belongs_to :geoname , :foreign_key => "geonameid"

  def self.find_or_create(geoname_id,tree_ids,tree_names)
    if GeonameHierarchy.find_by_geonameid(geoname_id).nil?
      return GeonameHierarchy.create_from_attributes(geoname_id,tree_ids,tree_names)
    else
      return GeonameHierarchy.update_from_attributes(geoname_id,tree_ids,tree_names)
    end
  end

  def self.create_from_attributes(geoname_id,tree_ids,tree_names)
    hierarchy = GeonameHierarchy.new(geonameid: geoname_id,
                    hierarchytree: tree_ids,
                    hierarchytreetopnoamy:tree_names)
    hierarchy.save!
    hierarchy
  end

  def self.update_from_attributes(geoname_id,tree_ids,tree_names)
    hierarchy = GeonameHierarchy.find_by_geonameid(geoname_id)
    hierarchy.update_attributes!(hierarchytree: tree_ids,
                          hierarchytreetopnoamy:tree_names)
    hierarchy.save!
    hierarchy
  end

  def eval_names_from_id(ids)
    geoname_ids=ids.split(',')
    names=[]
    geoname_ids.each{ |id|
      geoname=Geoname.find_by_geonameid(id)
      if geoname
        names<<geoname.asciiname
      else

      end
    }

  end

end