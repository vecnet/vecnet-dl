class HarvestController < ApplicationController
  include ApplicationHelper

  def show
    # Generate a complete list of resources, based on who the user is
    # For now only exports Citations and GenericFiles.
    # Could (Should?) export more items such as CitationFiles, Collections,
    # etc.
    #
    # BUG: we are not filtering by the user's groups
    since = params[:since]
    fq = []
    if since =~ /\A\d{4}-\d{2}-\d{2}\Z/
      fq << "desc_metadata__date_modified_dt:[#{since}T00:00:00Z TO NOW]"
    end
    fq << "-has_model_s:\"info:fedora/afmodel:Collection\""
    fq << "-has_model_s:\"info:fedora/afmodel:Batch\""
    fq << "-has_model_s:\"info:fedora/afmodel:CitationFile\""

    docs = []
    start = 0
    loop do
      query = {
        #qt: 'search',
        #raw: true,
        rows: 1000,
        start: start,
        fl: 'id,noid_s,desc_metadata__date_modified_dt,has_model_s',
        fq: fq.join(" "),
        sort: 'desc_metadata__date_modified_dt asc'
      }
      start += 1000

      new_docs = ActiveFedora::SolrService.query('*', query)
      break if new_docs.length == 0
      docs += new_docs
    end

    result = docs.map do |doc|
      { "url" => construct_show_url(doc),
        "last_modified" => doc["desc_metadata__date_modified_dt"]
      }
    end

    render json: result
  end
end
