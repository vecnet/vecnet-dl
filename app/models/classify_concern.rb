class ClassifyConcern
  VALID_CURATION_CONCERNS = {
    'Upload File' => 'Collection'
  }
  include ActiveAttr::Model
  attribute :curation_concern_type

  validates(
    :curation_concern_type,
    presence: true,
    inclusion: { in: VALID_CURATION_CONCERNS.values}
  )

  def possible_curation_concern_types
    VALID_CURATION_CONCERNS
  end

  def self.curation_types
    VALID_CURATION_CONCERNS
  end

  def single_curation
    VALID_CURATION_CONCERNS.values.first.constantize
  end

  def curation_concern_class
    if possible_curation_concern_types.detect{|name, class_name|
        class_name == curation_concern_type
      }
      curation_concern_type.constantize
    else
      raise RuntimeError, "Invalid :curation_concern_type"
    end
  end
end
