require Curate::Engine.root.join('app/controllers/curation_concern/base_controller')
require Curate::Engine.root.join('app/services/curation_concern')
class CurationConcern::CitationsController < CurationConcern::BaseController
  respond_to(:html,:endnote)

  def attach_action_breadcrumb
    add_breadcrumb 'Home', root_path
    case URI(request.referer).path
      when '/dashboard'
        add_breadcrumb 'Dashboard', dashboard_index_path
      when '/catalog'
        add_breadcrumb 'Back to Search results', request.referer
      when '/'
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

  def edit
    respond_with(curation_concern)
  end

  def update
    actor.update!
    respond_with([:curation_concern, curation_concern])
  rescue ActiveFedora::RecordInvalid
    respond_with([:curation_concern, curation_concern]) do |wants|
      wants.html { render 'edit', status: :unprocessable_entity }
    end
  end

  def show
    respond_with(curation_concern){|format|
      format.endnote { render :text => curation_concern.endnote_export }
    }
  end

  def destroy
    title = curation_concern.to_s
    curation_concern.destroy
    flash[:notice] = "Deleted #{title}"
    respond_with { |wants|
      wants.html { redirect_to redirect_to_dashboard }
    }
  end

  include Morphine
  register :actor do
    CurationConcern.actor(curation_concern, current_user, params[:citation])
  end
  private
  def show_breadcrumbs?
    true
  end

  def redirect_to_dashboard
    query_params = session[:search] ? session[:search].dup : {}
    query_params.delete :counter
    query_params.delete :total
    controller=query_params.delete :controller
    if controller.eql?("admin_dashboard")
      return admin_dashboard_index_path(query_params)
    else
      return dashboard_index_path(query_params)
    end
  end
end
