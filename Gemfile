source 'https://rubygems.org'

# This should be everything except :deploy; And by default, we mean any of
# the environments that are not used to execute the deploy scripts
group :default do
  gem 'pg'
  gem 'unicorn', '~> 4.0'
  #gem 'common_repository_model', git: 'git://github.com/ndlib/common_repository_model'
  #gem 'sufia', git: 'git://github.com/ndlib/sufia.git', branch: 'sufia-for-curate-nd'
  gem 'curate', path:'/Users/blakshmi/projects/hydra_curate/curate' #'~> 0.6.1'
  #gem 'blacklight-hierarchy', git: 'git://github.com/banurekha/blacklight-hierarchy.git'
  gem 'rsolr', git: 'git://github.com/jeremyf/rsolr.git', branch: 'adding-connection-information-to-error-handling'
  gem 'jettywrapper'
  gem 'jquery-rails'
  gem 'decent_exposure'
  gem 'rake'
  gem 'resque-pool'
  gem 'morphine'
  gem "unicode", :platforms => [:mri_18, :mri_19]
  gem 'warden', '~> 1.2.3'
  gem 'active_attr'
  gem 'browser'
  gem 'rubydora', "~>1.6.4"
  gem 'mods', git: 'git://github.com/banurekha/mods.git'
  gem 'rdf', '>= 1.0.10.1', '< 1.1'
  gem 'nokogiri', "~>1.6.0"
  #Rails 4 upgrade gem
  gem 'protected_attributes'
  gem 'blacklight_advanced_search', '~> 2.1.0'
  gem 'hydra-batch-edit', '>= 1.1.1', '< 2.0.0'
  gem "devise"
  gem "devise-guests", "~> 0.3"


  # Need rubyracer to run integration tests.....really?!?
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby
  gem 'method_decorators'
  gem 'rabl'
  gem 'chronic'

  # Hack to work around some bundler strangeness
  #
  # This gem was appearing in the lock file, but was not
  # being listed in a `bundle list` command on the staging machine.
  # Explicitly require it here.
  gem 'addressable', '~> 2.3.5'
end

group :headless do
  gem 'clamav'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do

  gem 'coffee-rails', '~> 4.0'
  gem 'compass-rails'
  gem 'sass-rails', '~> 4.0'
  gem 'uglifier', '>= 1.0.3'

  #gem 'bootstrap-sass', '~> 2.2.0'
  #gem 'font-awesome-sass-rails', '~> 2.0.0.0'
end

group :test do
  gem 'capybara', "~> 2.1"
  gem 'database_cleaner'
  gem 'factory_girl_rails', :require => false
  gem 'rspec-html-matchers'
  gem 'rspec-rails'
  gem 'vcr'
  gem 'webmock'
  gem 'timecop'
  gem 'poltergeist'
  gem 'test_after_commit'
  gem 'selenium-webdriver', '2.35.1'
end

group :debug do
  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller', :platforms => [:mri_19, :mri_20, :rbx]
  gem 'debugger', ">= 1.4"
  gem 'rails_best_practices'
  #gem 'sextant'
  gem 'simplecov'
  gem 'method_locator'
end

group :deploy do
  gem 'capistrano', '~> 2.15'
end
