require File.expand_path("../../repository_datastreams/generic_file_rdf_datastream", __FILE__)
require Curate::Engine.root.join('app/repository_models/generic_file')
class GenericFile
  include CurationConcern::ModelMethods
  include SpatialCoverage
  include TemporalMixin
  include Vecnet::ModelMethods
  include CurationConcern::WithSpecies

  attr_accessor :locations

  has_metadata :name => "comments", :type => CommentDatastream, :control_group => 'M'

  delegate_to :descMetadata, [:description], :unique => true
  delegate_to :descMetadata, [:conforms_to, :source, :bibliographic_citation]


  def spatials
     return Array(self.datastreams["descMetadata"].spatials).collect{|spatial| Spatial.parse_spatial(spatial)}
  end

  def spatials=(formated_str)
      self.datastreams["descMetadata"].spatials=formated_str
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

  def get_full_text
    # Trying to unify GenericFile and CitationFile interfaces
    return nil unless self.datastreams.has_key?("full_text")
    self.datastreams["full_text"].content
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["hierarchy_facet"] = LocalAuthority.mesh_hierarchical_faceting(self.subject)
    solr_doc["species_hierarchy_facet"] = NcbiSpeciesTerm.get_species_faceting((species.to_a + (subject || [])).uniq)
    # is this field needed?
    # solr_doc["subject_parents_t"] = XXXXXX get_subject_parents(self.subject)
    solr_doc["pub_dt"] = get_formated_date_created(self.date_created)
    solr_doc["pub_date"] = get_formated_date_created(self.date_created)
    solr_doc["title_alpha_sort"] = concat_title
    solr_doc["location_hierarchy_facet"] = LocalAuthority.geonames_hierarchical_faceting(self.based_near)
    #Temp solr fields for location until we fix geoname autocomplete
    solr_doc["location_facet"] = locations
    solr_doc["location_display"] = locations

    return solr_doc
  end

  def locations
    locations = self.based_near
    locations.map{ |loc| refactor_location(loc) }
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

  def thumbnail_noid
    self.noid
  end
end
