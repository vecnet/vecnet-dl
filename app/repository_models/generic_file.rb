require File.expand_path("../../repository_datastreams/generic_file_rdf_datastream", __FILE__)
require Curate::Engine.root.join('app/repository_models/generic_file')
class GenericFile
  include CurationConcern::ModelMethods
  include SpatialCoverage
  include Vecnet::ModelMethods
  include CurationConcern::WithSpecies
  include CurationConcern::WithExternalFiles

  attr_accessor :locations

  has_metadata :name => "comments", :type => CommentDatastream, :control_group => 'M'

  delegate_to :descMetadata, [:description], :unique => true


  def spatials
     return Array(self.datastreams["descMetadata"].spatials).collect{|spatial| Spatial.parse_spatial(spatial)}
  end

  def temporals
    return Array(self.datastreams["descMetadata"].temporals).collect{|temporal| Temporal.parse_temporal(temporal)}
  end

  def spatials=(formated_str)
      self.datastreams["descMetadata"].spatials=formated_str
  end

  def temporals=(formated_str)
    self.datastreams["descMetadata"].temporals=formated_str
  end

  def filename
    content.label
  end

  def to_s
    title || label || "No Title"
  end

  def versions
    content.versions
  end

  def current_version_id
    content.latest_version.nil? ? "" : content.latest_version.versionID
  end

  def current_version_just_id
    current_version_id.split('.').last
  end

  def human_readable_type
    self.class.to_s.demodulize.titleize
  end

  def endnote_export
    EndNote.new(self).to_endnote
  end

  def concat_title
    return nil if self.title.blank?
    return self.title.is_a?(Array) ? self.title.join(',') : self.title
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["hierarchy_facet"] = get_hierarchical_faceting_on_subject(self.subject)
    solr_doc["species_hierarchy_facet"] = get_hierarchical_faceting_on_species
    solr_doc["subject_parents_t"] = get_subject_parents(self.subject)
    solr_doc["pub_dt"] = get_formated_date_created(self.date_created)
    solr_doc["pub_date"] = get_formated_date_created(self.date_created)
    solr_doc["title_alpha_sort"] = concat_title
    solr_doc["location_hierarchy_facet"] = get_hierarchy_on_location(self.based_near)
    #Temp solr fields for location until we fix geoname autocomplete
    solr_doc["location_facet"] = locations
    solr_doc["location_display"] = locations

    return solr_doc
  end


  def locations
    locations=self.based_near
    new_locations=locations.map{|loc| refactor_location(loc) }
    new_locations
  end

  def refactor_location(location)
    return location.split(',').each_with_object([]) {|name, a| a<< name.strip unless name.to_s.strip.empty?}.uniq.join(',')
  end

  def update_related_files
    related_files.each do |generic_file|
      generic_file.rights = self.rights
      generic_file.creator = self.creator
      generic_file.tag = self.tag
      generic_file.date_modified = Time.now.ctime
      generic_file.save!
    end
  end
=begin
  def get_hierarchy_on_location
    unless self.based_near.blank?
      geoname_id_hash= LocationHierarchyServices.get_geoname_ids(self.based_near)
      location_trees=[]
      location_tree_to_solrize=[]
      geoname_id_hash.each do |location,geoname_id|
        hierarchy= GeonameHierarchy.find_by_geoname_id(geoname_id)
        hierarchy_with_earth=''
        if hierarchy && hierarchy.hierarchy_tree_name.present?
          hierarchy_with_earth= hierarchy.hierarchy_tree_name.gsub(';',':')
        else
          tree_id, tree_name = LocationHierarchyServices.find_hierarchy(geoname_id)
          hierarchy_with_earth=tree_name.gsub(';',':')
        end
        hierarchy_without_earth=hierarchy_with_earth.gsub('Earth:','')
        location_tree_to_solrize<<hierarchy_without_earth
      end
      location_trees<<location_tree_to_solrize.collect{|tree| LocationHierarchyServices.get_solr_hierarchy_from_tree(tree)}.flatten
      return location_trees.flatten
    end
    return nil
  end

  def get_formated_date_created
    return nil if self.date_created.blank?
    return @pub_date_sort.to_time.utc.iso8601 unless @pub_date_sort.nil?
    pub_date=self.date_created.first
    if self.date_created.size>1
      logger.error "#{self.pid} has more than one pub date, #{self.date_created.inspect}, but will only use #{pub_date} for sorting"
    end
    pub_date_replace=pub_date.gsub(/-|\/|,|\s/, '.')
    @pub_date_sort=pub_date_replace.split('.').size> 1? Chronic.parse(pub_date) : Date.strptime(pub_date,'%Y')
    return @pub_date_sort.to_time.utc.iso8601 unless @pub_date_sort.blank?
  end

  def get_subject_parents
    subjects=self.subject
    all_trees_arr=[]
    subjects.each do |sub|
      mesh_subject= SubjectMeshEntry.find_by_term(sub)
      if mesh_subject
        all_trees_arr<<mesh_subject.mesh_tree_structures.collect{|tree| tree.get_solr_hierarchy_from_tree}.flatten
      end
    end
    return all_trees_arr.uniq
  end

  def get_hierarchical_faceting_on_subject
    subjects=self.subject
    all_trees=[]
    subjects.each do |sub|
      mesh_subject= SubjectMeshEntry.find_by_term(sub)
      if mesh_subject
        all_trees<<mesh_subject.mesh_tree_structures.collect{|tree| tree.get_solr_hierarchy_from_tree}.flatten
      end
    end
    return all_trees.flatten
  end
=end
end

