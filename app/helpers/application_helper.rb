module ApplicationHelper
  def construct_show_path(solr_document, options = {})
    object_type=solr_document.has?('active_fedora_model_s') ? solr_document['active_fedora_model_s'].first : ""
    if object_type.eql?("Citation")
      return citations_path(solr_document[:noid_s].first)
    else
      return files_path(solr_document[:noid_s].first)
    end
  end
end