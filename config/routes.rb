Vecnet::Application.routes.draw do

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

  namespace :curation_concern, path: :concern do
    resources :collections
    resources :citations
    resources(
        :citation_files,
        only: [:new, :create],
        path: 'container/:parent_id/citation_files'
    )
    resources(
        :citation_files,
        only: [:show, :edit, :update, :destroy]
    )
  end

  match "catalog/subject/facet" => "catalog#subject_facet", :as => :catalog_subject_facet
  match "catalog/location/facet" => "catalog#location_facet", :as => :catalog_location_facet
  match "catalog/species/facet" => "catalog#species_facet", :as => :catalog_species_facet

  match "files/:id/(:version)" => "curation_concern/generic_files#show", via: :get, as: "files"

  match "citations/:id" => "curation_concern/citations#show", via: :get, as: "citations"

  match "downloads/:id/(:version)" => "downloads#show", via: :get, as: "download"

  # Authority vocabulary queries route
  match 'authorities/:term' => 'authorities#query', :via=> :get, :as=>'authority_query'
  root to: 'catalog#index'

  match "harvest" => "harvest#show"

  # The resque monitor
  namespace :admin do
    constraints Vecnet::AdminConstraint do
      mount Resque::Server, :at => "queues"
      match "usage" => "usage#index", via: :get, as: :usage
    end
  end

  # since there is no pubtkt login for development
  if Rails.env.development?
    match 'development_sessions/log_in' => "development_sessions#new", :via => :get
    # morally the next should be a delete action, but is a get to match how the
    # single sign on works in production
    match 'development_sessions/log_out' => "development_sessions#invalidate", :via => :get
    resources :development_sessions
  end
end
