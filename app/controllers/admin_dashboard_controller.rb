require 'blacklight/catalog'

class AdminDashboardController < ApplicationController
  include Hydra::BatchEditBehavior
  include Blacklight::Catalog
  include Blacklight::Configurable # comply with BL 3.7
  include Hydra::Controller::ControllerBehavior
  include ActionView::Helpers::DateHelper
  include BlacklightAdvancedSearch::ParseBasicQ
  include BlacklightAdvancedSearch::Controller
  include JoinSolrParams

  with_themed_layout 'dashboard'

  # This is needed as of BL 3.7
  self.copy_blacklight_config_from(CatalogController)

  #Removing sort field from config and readding to change order of sorting

  configure_blacklight.sort_fields.delete("score desc, pub_date_sort desc, title_sort asc")
  configure_blacklight.sort_fields.delete("pub_date_sort desc")
  configure_blacklight.sort_fields.delete("pub_date_sort asc")
  configure_blacklight.sort_fields.delete("desc_metadata__date_uploaded_dt desc")
  configure_blacklight.sort_fields.delete("desc_metadata__date_uploaded_dt asc")
  configure_blacklight.sort_fields.delete("desc_metadata__date_modified_dt desc")
  configure_blacklight.sort_fields.delete("desc_metadata__date_modified_dt asc")
  configure_blacklight.sort_fields.delete("title_alpha_sort asc")

  configure_blacklight do |config|
    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field 'pub_date_sort desc', :label => "Publish Date \u25BC"
    config.add_sort_field 'pub_date_sort asc', :label => "Publish Date \u25B2"
    config.add_sort_field 'title_alpha_sort asc', :label => "Title"
    config.add_sort_field 'desc_metadata__date_uploaded_dt desc', :label => "Date Uploaded \u25BC"
    config.add_sort_field 'desc_metadata__date_uploaded_dt asc', :label => "Date Uploaded \u25B2"
    config.add_sort_field 'desc_metadata__date_modified_dt desc', :label => "Date Modified \u25BC"
    config.add_sort_field 'desc_metadata__date_modified_dt asc', :label => "Date Modified \u25B2"
    config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'Relevancy'

  end

  before_filter :authenticate_user!

  # This filters out objects that you want to exclude from search results, like FileAssets
  AdminDashboardController.solr_search_params_logic += [:exclude_unwanted_models]

 def index
    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => "RSS for results")
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => "Atom for results")
    (@response, @document_list) = get_search_results
    @user = current_user
    @events = @user.events(100)
    @last_event_timestamp = @user.events.first[:timestamp].to_i || 0 rescue 0
    @filters = params[:f] || []

    # adding a key to the session so that the history will be saved so that batch_edits select all will work
    search_session[:admin_dashboard] = true
    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end

    # set up some parameters for allowing the batch controls to show appropiately
    @max_batch_size = 80
    count_on_page = @document_list.count {|doc| batch.index(doc.id)}
    @disable_select_all = @document_list.count > @max_batch_size
    batch_size = batch.uniq.size
    @result_set_size = @response.response["numFound"]
    @empty_batch = batch.empty?
    @all_checked = (count_on_page == @document_list.count)
    @entire_result_set_selected = @response.response["numFound"] == batch_size
    @batch_size_on_other_page = batch_size - count_on_page
    @batch_part_on_other_page = (@batch_size_on_other_page) > 0
  end

  def get_related_file
    @user = current_user
    #Need to make sure if params get in ways of searching (like page,per_page,q,f). If that happens then have to remove from params and put back in
    extra_controller_params = {}
    extra_controller_params.merge!(:fq=>"")
    @response, @document_list = get_solr_response_for_field_values("is_part_of_s",["info:fedora/#{params[:id]}"],extra_controller_params)
  end

  private

  def show_site_search?
    false
  end

  protected

  def exclude_unwanted_models(solr_parameters, user_parameters)
    super
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "-has_model_s:\"info:fedora/afmodel:Collection\""
    solr_parameters[:fq] << "-has_model_s:\"info:fedora/afmodel:CitationFile\""
    return solr_parameters
  end
end
