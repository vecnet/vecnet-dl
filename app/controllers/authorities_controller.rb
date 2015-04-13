require 'rdf'
require 'cgi'
require File.expand_path('../../models/local_authority', __FILE__)

class AuthoritiesController < ApplicationController
  def query
    s = params.fetch("q", "")
    case params[:term]
    when "location"
      hits = GeoNamesResource.find_location(s)
    when "species"
      hits = LocalAuthority.entries_by_species(s)
    when "subject"
      hits = LocalAuthority.entries_by_subject_mesh_term(s)
    else
      hits = []
    end
    render json: hits
  end
end
