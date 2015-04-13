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
    when "subject-hierarchy"
      hits = LocalAuthority.mesh_hierarchical_faceting([s])
    when "species-hierarchy"
      hits = NcbiSpeciesTerm.get_species_faceting([s])
    when "location-hierarchy"
      hits = LocalAuthority.geonames_hierarchical_faceting([s])
    else
      hits = []
    end
    render json: hits
  end
end
