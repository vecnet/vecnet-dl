CurateNd::Application.routes.draw do

  devise_for :users

  resources 'role_dashboard', :only=>:index do
    collection do
      get 'page/:page', :action => :index
      get 'facet/:id',  :action => :facet, :as => :facet
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

  # Authority vocabulary queries route
  match 'authorities/:model/:term' => 'authorities#query', :via=> :get, :as=>'authority_query'
  root to: 'catalog#index'

end
