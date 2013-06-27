require File.expand_path("../../repository_datastreams/generic_file_rdf_datastream", __FILE__)
require Curate::Engine.root.join('app/repository_models/generic_file')
class GenericFile
  include CurationConcern::ModelMethods
  include SpatialCoverage

  delegate_to :descMetadata, [:description], :unique => true

  validates :title, presence: { message: 'Your must have a title.' }
  validates :rights, presence: { message: 'You must select a license for your work.' }
  validates :creator, presence: { message: "You must have an author."}
  validates :tag, presence: { message: "You must have a keyword."}

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
    content.latest_version.versionID
  end

  def human_readable_type
    self.class.to_s.demodulize.titleize
  end

  def endnote_export
    EndNote.new(self).to_endnote
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["hierarchy_facet"] = get_hierarchical_faceting_on_subject
    solr_doc["subject_parents_t"] = get_subject_parents
    return solr_doc
  end

  def get_subject_parents
    subjects=self.subject
    all_trees_arr=[]
    subjects.each do |sub|
      all_trees_arr<<SubjectMeshEntry.find_by_term(sub).mesh_tree_structures.collect{|tree| tree.eval_tree_path}.flatten
    end

    return all_trees_arr.uniq
  end

  def get_hierarchical_faceting_on_subject
    subjects=self.subject
    all_trees=[]
    subjects.each do |sub|
      all_trees<<SubjectMeshEntry.find_by_term(sub).mesh_tree_structures.collect{|tree| tree.get_solr_hierarchy_from_tree}.flatten
    end
    puts "get_solr_hierarchy_from_tree Index to :#{all_trees.inspect}"
    return all_trees
  end


end

