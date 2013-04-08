module CurationConcern
  class CollectionActor < CurationConcern::BaseActor

    def initialize(curation_concern, user, input_attributes)
      @curation_concern = curation_concern
      @user = user
    end

    def save
      curation_concern.save!
    end

    def create!
      save
    end

    def update!
      super
      update_contained_generic_file_visibility
    end

    protected

    def update_contained_generic_file_visibility
      if visibility_may_have_changed?
        curation_concern.generic_files.each do |f|
          f.set_visibility(visibility)
          f.save!
        end
      end
    end
  end
end
