require 'curation_concern/model'
class Citation < ActiveFedora::Base
  include CurationConcern::Model
  include CurationConcern::WithCitationFiles
  include CurationConcern::WithAccessRight
  include CurationConcern::ModelMethods
  include CurationConcern::Embargoable
  include SpatialCoverage
  include TemporalMixin
  include Vecnet::ModelMethods
  include CurationConcern::WithSpecies

  self.human_readable_short_description = "Citation"

  has_metadata name: "descMetadata", type: CitationRdfDatastream, control_group: 'M'

  #delegate_to :properties, [:relative_path, :depositor], :unique => true
  delegate_to :descMetadata, [:date_uploaded, :date_modified, :title, :description], :unique => true
  delegate_to :descMetadata, [:related_url, :based_near, :part_of, :creator,
                              :contributor, :tag, :rights,
                              :publisher, :date_created, :subject,
                              :resource_type, :identifier, :language, :bibliographic_citation,
                              :archived_object_type, :references, :source, :alternative, :conforms_to]

  attr_accessor :files

  def spatials
    return Array(self.datastreams["descMetadata"].spatials).collect{|spatial| Spatial.parse_spatial(spatial)}
  end

  def spatials=(formated_str)
    self.datastreams["descMetadata"].spatials=formated_str
  end


  def human_readable_type
    self.class.to_s.demodulize.titleize
  end

  def concat_title
    return nil if self.title.blank?
    return self.title.is_a?(Array) ? self.title.join(',') : self.title
  end

  def current_version_just_id
    descMetadata.versions.last.versionID.split(".").last
  end

  def endnote_export
    EndNote.new(self).to_endnote
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
    new_locations = locations.map{|loc| refactor_location(loc) }
    new_locations
  end

  # this is a low-effort attempt at cleaning up location data
  # Is it even necessary??
  def refactor_location(location)
    result = []
    location.split(',').each do |name|
      result << name.strip unless name.to_s.strip.empty?
    end
    result.uniq.join(',')
  end

  #one time conversion for converting bib data, not need anymore
  #XXX(dbrower): this makes my head hurt
  def reformat_bibliographic_citation
    return '' if self.bibliographic_citation.blank? || self.bibliographic_citation.first.gsub(/[,():\/s]/,'').blank?
    citation=self.bibliographic_citation.first
    journal=self.source.blank? ? '' : self.source.first
    pubdate= self.date_created.blank? ? '' : self.date_created.first
    citation_arr=citation.split(':')
    issue_details= citation_arr.first.gsub(journal, '').gsub(pubdate,'').gsub(/[^a-zA-Z0-9,]/,'').split(',')
    unless issue_details.blank?
      volume=issue_details.first
      issue=issue_details.last
      formatted_volume = issue_details.count == 2 ? " #{volume}(#{issue})" : " #{issue_details.join(' ')}"
    end
    pages= citation_arr.last.gsub('page','').gsub(/[\s]/,'')
    formated_pages = ''
    formated_pages = pages.split('-').count == 2 ? ", #{pages.strip}" : ", #{pages.gsub(/[-]/,'')}" unless pages.gsub(/[-]/,'').blank?
    format_publish_date = pubdate.blank? ? '' : " (#{pubdate})"
    first_part = "#{journal}#{formatted_volume}#{formated_pages}"
    first_part.blank? ? format_publish_date : "#{first_part}.#{format_publish_date}"
  end

  def update_bibliographic_citation
    self.alternative=self.bibliographic_citation
    self.bibliographic_citation=reformat_bibliographic_citation
    self.save!
  end

  def update_citation_resource_type
    self.resource_type='Article'
    self.save!
  end

  def thumbnail_noid
    gf = self.generic_files.first
    gf.nil? ? nil : gf.noid
  end

  # just the size of the citation obj, does not include its children
  def size
    self.datastreams.values.map(&:size).compact.sum
  end

end
