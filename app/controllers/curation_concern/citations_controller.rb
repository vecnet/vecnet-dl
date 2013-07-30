require Curate::Engine.root.join('app/controllers/curation_concern/base_controller')
require Curate::Engine.root.join('app/services/curation_concern')
class CurationConcern::CitationsController < CurationConcern::BaseController
  respond_to(:html)

  def attach_action_breadcrumb
    add_breadcrumb 'Home', root_path
    case request.referer
      when /dashboard/
        add_breadcrumb 'Dashboard', dashboard_index_path
      when /catalog/
        add_breadcrumb 'Back to Search results', request.referer
    end
    super
  end

  before_filter :curation_concern
    
  def curation_concern
    @curation_concern ||=
    if params[:id]
      Citation.find(params[:id])
    end
  end
  def show
    respond_with(curation_concern)
  end

  def destroy
    title = curation_concern.to_s
    curation_concern.destroy
    flash[:notice] = "Deleted #{title}"
    respond_with { |wants|
      wants.html { redirect_to dashboard_index_path }
    }
  end
end
