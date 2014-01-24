Vecnet::Application.routes.draw do

  Blacklight.add_routes(self)
  HydraHead.add_routes(self)

  curate_for containers: [:citations, :documents]

  root 'catalog#index'

  resources 'role_dashboard', :only=>:index do
    collection do
      get 'page/:page', :action => :index
      get 'facet/:id',  :action => :facet, :as => :roles_facet
    end
  end

  resources 'admin_dashboard', :only=>:index do
    collection do
      get 'page/:page', :action => :index
      get 'facet/:id',  :action => :facet, :as => :admin_facet
    end
  end

  #namespace :curation_concern, path: :concern do
  #  resources :collections
  #  resources :citations
  #  resources(
  #      :citation_files,
  #      only: [:new, :create],
  #      path: 'container/:parent_id/citation_files'
  #  )
  #  resources(
  #      :citation_files,
  #      only: [:show, :edit, :update, :destroy]
  #  )
  #end


  get "catalog/recent" => "catalog#recent", :as => :catalog_recent

  get "catalog/subject/facet" => "catalog#subject_facet", :as => :catalog_subject_facet
  get "catalog/location/facet" => "catalog#location_facet", :as => :catalog_location_facet
  get "catalog/species/facet" => "catalog#species_facet", :as => :catalog_species_facet

  get "files/:id/(:version)" => "curation_concern/generic_files#show",  as: "files"

  get "citations/:id" => "curation_concern/citations#show",  as: "citations"

  # Authority vocabulary queries route
  get 'authorities/:model/:term' => 'authorities#query', :as=>'authority_query'

  # The resque monitor
  namespace :admin do
    constraints Vecnet::AdminConstraint do
      mount Resque::Server, :at => "queues"
    end
  end

  # since there is no pubtkt login for development
  if Rails.env.development?
    get 'development_sessions/log_in' => "development_sessions#new"
    # morally the next should be a delete action, but is a get to get how the
    # single sign on works in production
    get 'development_sessions/log_out' => "development_sessions#invalidate"
    resources :development_sessions
  end
end
