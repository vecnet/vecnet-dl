require 'sufia/noid'

class DownloadsController < ApplicationController
  include Sufia::Noid # for normalize_identifier method

  ## Exception Handling
  class NotLatestVersion < StandardError
  end

  def generic_file
    @generic_file ||= GenericFile.find(params[:id])
  end

  def verify_version_to_download
    if params.has_key?(:version)
      logger.debug "checking version"
      #raise NotLatestVersion.new("Version your are trying to download is out dated. Cannot download out dated version") unless generic_file.current_version_just_id == params[:version]
      render :text => "Version your are trying to download is out dated. Cannot download out dated version", :status => 403, :layout=>true unless generic_file.current_version_just_id == params[:version]
    end
  end

  before_filter :generic_file
  before_filter :verify_version_to_download, :only=>:show
  prepend_before_filter :normalize_identifier, except: [:index, :new, :create]

  def show
    logger.debug "Test"
    authorize!(:show, generic_file)
    send_content (generic_file)
  end

  protected
  def send_content (asset)
    opts = {}
    ds = nil
    opts[:filename] = params["filename"] || asset.label
    opts[:disposition] = 'inline'
    if params.has_key?(:datastream_id)
      opts[:filename] = params[:datastream_id]
      ds = asset.datastreams[params[:datastream_id]]
    end
    ds = asset.datastreams["content"] if ds.nil?
    raise ActionController::RoutingError.new('Not Found') if ds.nil?
    data = ds.content
    opts[:type] = ds.mimeType
    send_data data, opts
    return
  end
end
