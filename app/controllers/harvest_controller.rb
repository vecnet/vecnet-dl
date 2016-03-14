class HarvestController < ApplicationController
  include ApplicationHelper

  # these need to be ordered from longest to shortest (see logic below)
  DATE_FORMATS = ['%Y-%m-%dT%H:%M:%S',
                  '%Y-%m-%dT%H:%M',
                  '%Y-%m-%dT%H',
                  '%Y-%m-%d',
                  '%Y-%m',
                  '%Y'].freeze

  def show
    # Generate a complete list of resources, based on who the user is
    # For now only exports Citations and GenericFiles.
    # Could (Should?) export more items such as CitationFiles, Collections,
    # etc.
    #
    # We would use `desc_metadata__date_modified_dt` but it only has date
    # grainularity. Instead we use `system_modified_dt`, which is the time
    # the _solr_ record was last updated.
    #
    # BUG: we are not filtering by the user's groups
    since = params[:since]
    dt = nil
    unless since.nil?
      DATE_FORMATS.each do |format|
        dt = try_parse_time(since, format)
        break unless dt.nil?
      end
    end

    fq = []
    unless dt.nil?
      fq << "timestamp:[" + dt.strftime('%Y-%m-%dT%H:%M:%S') + "Z TO NOW]"
    end
    fq << "-active_fedora_model_s:Collection"
    fq << "-active_fedora_model_s:Batch"
    fq << "-active_fedora_model_s:CitationFile"

    docs = []
    start = 0
    loop do
      query = {
        #qt: 'search',
        #raw: true,
        rows: 1000,
        start: start,
        fl: 'id,noid_s,timestamp,active_fedora_model_s',
        fq: fq.join(" "),
        sort: 'system_modified_dt asc'
      }
      start += 1000

      new_docs = ActiveFedora::SolrService.query('*', query)
      break if new_docs.length == 0
      docs += new_docs
    end

    result = docs.map do |doc|
      next if doc["noid_s"].nil?
      { "url" => construct_show_url(doc),
        "last_modified" => doc["timestamp"]
      }
    end

    render json: result
  end

  def try_parse_time(input, format)
    DateTime.strptime(input, format)
  rescue ArgumentError
    nil
  end
end
