require File.expand_path("../../repository_datastreams/generic_file_rdf_datastream", __FILE__)
require Curate::Engine.root.join('app/repository_models/generic_file')
class GenericFile
  include CurationConcern::ModelMethods
  include SpatialCoverage

  has_metadata :name => "comments", :type => CommentDatastream, :control_group => 'M'

  delegate_to :descMetadata, [:description], :unique => true

  validates :title, presence: { message: 'Your must have a title.' }
  validates :rights, presence: { message: 'You must select a license for your work.' }
  validates :creator, presence: { message: "You must have an author."}

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
    solr_doc["hierarchy_facet"] = get_hierarchical_faceting_on_subject
    solr_doc["subject_parents_t"] = get_subject_parents
    solr_doc["pub_dt"] = get_formated_date_created
    solr_doc["pub_date"] = get_formated_date_created
    solr_doc["title_alpha_sort"] = concat_title
    return solr_doc
  end

  def get_formated_date_created
    return nil if self.date_created.blank?
    return @pub_date_sort.to_time.utc.iso8601 unless @pub_date_sort.nil?
    pub_date=self.date_created.first
    if self.date_created.size>1
      logger.error "#{self.pid} has more than one pub date, #{self.date_created.inspect}, but will only use #{pub_date} for sorting"
    end
    puts "Is nil: #{self.date_created.blank?}, Pub date to sort: #{pub_date.inspect}"
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


end

