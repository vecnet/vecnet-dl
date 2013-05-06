require Curate::Engine.root.join('app/controllers/classify_concerns_controller.rb')
class ClassifyConcernsController

  def new
    if ClassifyConcern.curation_types.size ==1
      respond_with(classify_concern) do |wants|
        wants.html do
          redirect_to new_polymorphic_path(
                          [:curation_concern, classify_concern.single_curation]
                      )
        end
      end
    else
      respond_with(classify_concern)
    end
  end
end
