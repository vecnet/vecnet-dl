require 'curation_concern/model'
class Citation < ActiveFedora::Base
  include CurationConcern::Model
  include CurationConcern::WithCitationFiles
  include CurationConcern::WithAccessRight
  include CurationConcern::ModelMethods
  include CurationConcern::Embargoable
  include SpatialCoverage
  self.human_readable_short_description = "Citation from Endnote"

  has_metadata name: "descMetadata", type: CitationRdfDatastream, control_group: 'M'

  #delegate_to :properties, [:relative_path, :depositor], :unique => true
  delegate_to :descMetadata, [:date_uploaded, :date_modified, :title], :unique => true
  delegate_to :descMetadata, [:related_url, :based_near, :part_of, :creator,
                              :contributor, :tag, :description, :rights,
                              :publisher, :date_created, :subject,
                              :resource_type, :identifier, :language, :bibliographic_citation, :archived_object_type, :references, :source]

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

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["hierarchy_facet"] = get_hierarchical_faceting_on_subject
    solr_doc["subject_parents_t"] = get_subject_parents
    solr_doc["pub_date"] = get_formated_date_created
    return solr_doc
  end

  def get_formated_date_created
    return nil if self.date_created.nil?
    return @pub_date_sort.to_time.utc.iso8601 unless @pub_date_sort.nil?
    pub_date=self.date_created.first
    if self.date_created.size>1
      logger.error "#{self.pid} has more than one pub date, #{self.date_created.inspect}, but will only use #{pub_date} for sorting"
    end
    pub_date_replace=pub_date.gsub(/-|\/|,|\s/, '.')
    @pub_date_sort=pub_date_replace.split('.').size> 1? Chronic.parse(pub_date) : Date.strptime(pub_date,'%Y')
    puts "Pid: #{pid.inspect} with date created as #{self.date_created.inspect} has Pub date to sort: #{@pub_date_sort.inspect}"
    return @pub_date_sort.to_time.utc.iso8601
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

end
