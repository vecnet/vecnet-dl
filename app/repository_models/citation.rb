require 'curation_concern/model'
class Citation < ActiveFedora::Base
  include CurationConcern::Model
  include CurationConcern::WithCitationFiles
  include CurationConcern::WithAccessRight
  include CurationConcern::ModelMethods
  include CurationConcern::Embargoable
  include SpatialCoverage
  include Vecnet::ModelMethods
  include CurationConcern::WithSpecies

  self.human_readable_short_description = "Citation from Endnote"

  has_metadata name: "descMetadata", type: CitationRdfDatastream, control_group: 'M'

  #delegate_to :properties, [:relative_path, :depositor], :unique => true
  delegate_to :descMetadata, [:date_uploaded, :date_modified, :title, :description], :unique => true
  delegate_to :descMetadata, [ :related_url, :based_near, :part_of, :creator,
                              :contributor, :tag, :rights,
                              :publisher, :date_created, :subject,
                              :resource_type, :identifier, :language, :bibliographic_citation, :archived_object_type, :references, :source, :alternative]

  attr_accessor :files

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

  def human_readable_type
    self.class.to_s.demodulize.titleize
  end

  def concat_title
    return nil if self.title.blank?
    return self.title.is_a?(Array) ? self.title.join(',') : self.title
  end

  def endnote_export
    EndNote.new(self).to_endnote
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["hierarchy_facet"] = get_hierarchical_faceting_on_subject(self.subject)
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

=begin
  def get_formated_date_created
    return nil if self.date_created.blank?
    return @pub_date_sort.to_time.utc.iso8601 unless @pub_date_sort.nil?
    pub_date=self.date_created.first
    if self.date_created.size>1
      logger.error "#{self.pid} has more than one pub date, #{self.date_created.inspect}, but will only use #{pub_date} for sorting"
    end
    pub_date_replace=pub_date.gsub(/-|\/|,|\s/, '.')
    @pub_date_sort=pub_date_replace.split('.').size> 1? Chronic.parse(pub_date) : Date.strptime(pub_date,'%Y')
    puts "Pid: #{pid.inspect} with date created as #{self.date_created.inspect} has Pub date to sort: #{@pub_date_sort.inspect}"
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

  #one time conversion for converting bib data, not need anymore
  def reformat_bibliographic_citation
    return '' if self.bibliographic_citation.blank? || self.bibliographic_citation.first.gsub(/[,():\/s]/,'').blank?
    space=' '
    comma=','
    dot='.'
    formatted_volume=''
    formated_pages=''
    citation=self.bibliographic_citation.first
    journal=self.source.blank? ? '' : self.source.first
    pubdate= self.date_created.blank? ? '' : self.date_created.first
    citation_arr=citation.split(':')
    issue_details= citation_arr.first.gsub(journal, '').gsub(pubdate,'').gsub(/[^a-zA-Z0-9,]/,'').split(',')
    unless issue_details.blank?
      volume=issue_details.first
      issue=issue_details.last
      formatted_volume=issue_details.count==2 ? "#{space}#{volume}(#{issue})" : "#{space}#{issue_details.join(' ')}"
    end
    pages= citation_arr.last.gsub('page','').gsub(/[\s]/,'')
    #volume=issue_details.strip.split(',').count==2 ? "#{space}#{issue_details}" : "#{space}#{issue_details.gsub(/[,\/s]/,'')}"
    #formatted_volume=volume.blank? ? '': "#{space}#{volume}"
    formated_pages=pages.split('-').count==2 ? "#{comma}#{space}#{pages.strip}" : "#{comma}#{space}#{pages.gsub(/[-]/,'')}"unless pages.gsub(/[-]/,'').blank?
    format_publish_date=pubdate.blank? ? '' : "#{space}(#{pubdate})"
    first_part="#{journal}#{formatted_volume}#{formated_pages}"
    return first_part.blank? ? format_publish_date : "#{first_part}#{dot}#{format_publish_date}"
  end

  def update_citation
    self.alternative=self.bibliographic_citation
    self.bibliographic_citation=reformat_bibliographic_citation
    self.save!
  end

  def update_citation_resource_type
    self.resource_type='Article'
    self.save!
  end

end
