require Curate::Engine.root.join('app/repository_models/curation_concern/with_full_text.rb')
class CitationFile < ActiveFedora::Base

  include Sufia::GenericFile
  include CurationConcern::WithAccessRight
  include CurationConcern::WithFullText

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

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc["all_text_unstem_search"] = full_text.content if self.respond_to?(:full_text)
  end

end

