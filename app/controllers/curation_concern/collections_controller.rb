class CurationConcern::CollectionsController < CurationConcern::BaseController
  respond_to(:html)
  layout 'curate_nd/1_column'

  def curation_concern
    @curation_concern ||=
        if params[:id]
          Collection.find(params[:id])
        else
          Collection.new(params[:collection])
        end
  end

  def new
    create
  end

  def create
    begin
      @curation_concern = Collection.new(pid: CurationConcern.mint_a_pid)
      actor.create!
      respond_for_create
    rescue ActiveFedora::RecordInvalid
      respond_with([:curation_concern, curation_concern]) do |wants|
        wants.html { redirect_to new_classify_concern_path, status: :unprocessable_entity }
      end
    end

  end

  def respond_for_create
    respond_to do |wants|
      wants.html {
        redirect_to new_curation_concern_generic_file_path(curation_concern)
      }
   end
  end
  protected :respond_for_create

  def show
    respond_with(curation_concern)
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

  def destroy
    title = curation_concern.to_s
    curation_concern.destroy
    flash[:notice] = "Deleted #{title}"
    respond_with { |wants|
      wants.html { redirect_to dashboard_index_path }
    }
  end

  include Morphine
  register :actor do
    CurationConcern.actor(curation_concern, current_user,params[:collection])
  end
end
