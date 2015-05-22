class GeonameHierarchy < ActiveRecord::Base
  self.table_name = 'geoname_hierarchy'
  attr_accessible :geoname_id, :hierarchy_tree, :hierarchy_tree_name
  belongs_to :geoname , :foreign_key => "geoname_id"

  def self.find_or_create(geoname_id,tree)
    hierarchy = GeonameHierarchy.find_by_geoname_id(geoname_id)
    if hierarchy.nil?
      return GeonameHierarchy.create_from_attributes(geoname_id,tree)
    elsif ! tree.blank?
      hierarchy.update_attributes!(hierarchy_tree: tree,
                            hierarchy_tree_name:eval_tree(tree))
      hierarchy.save!
    end
    hierarchy
  end

  def self.create_from_attributes(geoname_id,tree_ids)
    if tree_ids.blank?
      return GeonameHierarchy.create!(geoname_id: geoname_id )
    else
      return GeonameHierarchy.create!(geoname_id: geoname_id,
                           hierarchy_tree: tree_ids,
                           hierarchy_tree_name:eval_tree(tree_ids))
    end
  end

  def self.eval_tree(tree)
    geoname_ids = tree.split('.')
    geonames = geoname_ids.map{|id| self.get_name_from_id(id)}
    geonames.join(';')
  end

  def self.get_name_from_id(id)
    geoname = Geoname.find(id)
    return geoname.name if geoname
    #TODO query getJSON for given id to get the name and whole record, update geoname table and return that name
    id
  end
end
