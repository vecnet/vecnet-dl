class CurationConcern::GenericFilesController < CurationConcern::BaseController
  respond_to(:html, :json)

  before_filter :parent
  before_filter :curation_concern
  load_resource :parent, class: "ActiveFedora::Base"

  def parent
    @parent ||=
    if params[:id]
      curation_concern.batch
    else
      ActiveFedora::Base.find(namespaced_parent_id,cast: true)
    end
  end
  helper_method :parent

  def namespaced_parent_id
    Sufia::Noid.namespaceize(params[:parent_id])
  end
  protected :namespaced_parent_id

  def curation_concern
    @curation_concern ||=
    if params[:id]
      GenericFile.find(params[:id])
    else
      GenericFile.new(params[:generic_file])
    end
  end

  def new
    respond_with(curation_concern){ |wants|
      wants.html {}
    }
  end

  def create
    curation_concern.batch = parent
    actor.create!
    redirect_to dashboard_index_path
  rescue ActiveFedora::RecordInvalid
    respond_with([:curation_concern, curation_concern]) { |wants|
      wants.html { render 'new', status: :unprocessable_entity }
    }
  end


  def show
    respond_with(curation_concern)
  end

  def edit
    respond_with(curation_concern)
  end

  def update
    actor.update!
    redirect_to edit_curation_concern_generic_file_path(curation_concern)
  rescue ActiveFedora::RecordInvalid
    respond_with([:curation_concern, curation_concern]) { |wants|
      wants.html { render 'edit', status: :unprocessable_entity }
    }
  end

  def destroy
    parent = curation_concern.batch
    title = curation_concern.to_s
    curation_concern.destroy
    flash[:notice] = "Deleted #{title}"
    respond_with([:curation_concern, parent])
  end

  include Morphine
  register :actor do
    CurationConcern.actor(curation_concern, current_user, params[:generic_file])
  end
end
