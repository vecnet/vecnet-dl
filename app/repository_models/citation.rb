require 'curation_concern/model'
class Citation < ActiveFedora::Base
  include CurationConcern::Model
  include CurationConcern::WithCitationFiles
  include CurationConcern::WithAccessRight
  include CurationConcern::ModelMethods
  self.human_readable_short_description = "Citation from Endnote"

  has_metadata name: "descMetadata", type: CitationRdfDatastream, control_group: 'M'

  #delegate_to :properties, [:relative_path, :depositor], :unique => true
  delegate_to :descMetadata, [:date_uploaded, :date_modified, :title], :unique => true
  delegate_to :descMetadata, [:related_url, :based_near, :part_of, :creator,
                              :contributor, :tag, :description, :rights,
                              :publisher, :date_created, :subject,
                              :resource_type, :identifier, :language, :bibliographic_citation, :archived_object_type, :references, :source]

  attr_accessor :files

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
