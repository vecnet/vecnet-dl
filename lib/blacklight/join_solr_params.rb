# lib/unstem_solr_params.rb
# Add on to CatalogController or another SolrHelper
#, to support :unstem_search param to search only un-stemmed fields.

module JoinSolrParams
  extend ActiveSupport::Concern

  included do
    solr_search_params_logic << :add_join_query_to_solr
  end

  def escape_quotes(s)
    s.gsub('"', '\\\\"').gsub("'", "\\\\'")
  end

  #If include full_text on citation is selected that need to join on citation file solr document
  #to match on parse withing fulltext
  def add_join_query_to_solr(solr_parameters, user_parameters = params)
    if user_parameters[:include_full_text] && user_parameters[:citation]
      solr_parameters[:q] ||= []
      join_caluse = solr_parameters[:q].empty? ? '' : ' OR '
      solr_parameters[:q] << join_caluse + "_query_:\"{!join from=parent_id_s to=id}all_text_unstem_search:#{escape_quotes(user_parameters[:citation])}\""
    end
    return solr_parameters
  end
end
