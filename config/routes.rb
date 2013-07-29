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
  end

  # User profile & follows
  match 'users' => 'users#index', :as => :profiles, :via => :get
  match 'users/:uid' => 'users#show', :as => :profile, :via => :get
  match 'users/:uid/edit' => 'users#edit', :as => :edit_profile, :via => :get
  match 'users/:uid/update' => 'users#update', :as => :update_profile, :via => :put

  match "catalog/recent" => "catalog#recent", :as => :catalog_recent

  match "catalog/subject/facet" => "catalog#subject_facet", :as => :catalog_subject_facet

  match "files/:id" => "curation_concern/generic_files#show", via: :get, as: "files"

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
    match 'development_sessions/log_out' => "development_sessions#destroy", :via => :post
    resources :development_sessions
  end

end
