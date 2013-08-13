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
    resources :citations, except: :edit
  end

  # User profile & follows
  match 'users' => 'users#index', :as => :profiles, :via => :get
  match 'users/:uid' => 'users#show', :as => :profile, :via => :get
  match 'users/:uid/edit' => 'users#edit', :as => :edit_profile, :via => :get
  match 'users/:uid/update' => 'users#update', :as => :update_profile, :via => :put

  match "catalog/recent" => "catalog#recent", :as => :catalog_recent

  match "catalog/subject/facet" => "catalog#subject_facet", :as => :catalog_subject_facet

  match "files/:id/(:version)" => "curation_concern/generic_files#show", via: :get, as: "files"

  match "citations/:id" => "curation_concern/citations#show", via: :get, as: "citations"

  match "downloads/:id/(:version)" => "downloads#show", via: :get, as: "download"

  # Authority vocabulary queries route
  match 'authorities/:model/:term' => 'authorities#query', :via=> :get, :as=>'authority_query'
  root to: 'catalog#index'

  # The resque monitor
  namespace :admin do
    constraints Vecnet::AdminConstraint do
      mount Resque::Server, :at => "queues"
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
