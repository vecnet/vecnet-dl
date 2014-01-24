class CitationFile < ActiveFedora::Base

  include Sufia::GenericFile
  #include CurationConcern::WithAccessRights
  include CurationConcern::WithFullText
  include CurationConcern::Embargoable
  include CurationConcern::ModelMethods

  belongs_to :batch, property: :is_part_of, class_name: 'ActiveFedora::Base'

  validates :batch, presence: true
  validates :file, presence: true, on: :create

  attr_accessor :file, :version

  class_attribute :human_readable_short_description
  self.human_readable_short_description = "Citation file attached as part of citation"

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

  def get_full_text
    #Sometime full text content is not available when saving (during characterization and pdf creation, so need to relaod object just to make sure it is available always)
    if self.full_text.content.nil?
      CitationFile.find(self.pid).full_text.content
    else
      return self.full_text.content
    end
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["noid_s"] = noid
    solr_doc["all_text_unstem_search"] = get_full_text unless get_full_text.blank?
    solr_doc["parent_id_s"] = self.batch.pid
    return solr_doc
  end

  def to_param
    noid
  end

  def update_visibility_as_authenticated
    self.set_visibility(AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
    self.save!
  end

end

