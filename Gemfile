source 'https://rubygems.org'

# This should be everything except :deploy; And by default, we mean any of
# the environments that are not used to execute the deploy scripts
group :default do
  gem 'rails', '3.2.11'
  gem 'pg'
  gem 'unicorn'
  gem 'common_repository_model', git: 'git://github.com/ndlib/common_repository_model'
  gem 'sufia', git: 'git://github.com/ndlib/sufia.git', branch: 'sufia-for-curate-nd'
  gem 'curate', git: 'git://github.com/banurekha/curate.git', branch: 'vecnet'
  gem 'blacklight-hierarchy', git: 'git://github.com/banurekha/blacklight-hierarchy.git'
  gem 'solrizer'#, git: 'git://github.com/ndlib/solrizer.git'
  gem 'solrizer-fedora' # just to get resolrizer task
  gem 'rsolr', git: 'git://github.com/jeremyf/rsolr.git', branch: 'adding-connection-information-to-error-handling'
  gem 'jettywrapper'
  gem 'jquery-rails'
  gem 'decent_exposure'
  gem 'rake'
  gem 'resque-pool'
  gem 'morphine'
  gem "unicode", :platforms => [:mri_18, :mri_19]
  gem "devise"
  gem "devise-guests", "~> 0.3"
  gem 'simple_form'
  gem 'roboto'
  gem 'active_attr'
  gem 'browser'
  gem 'rubydora', "~>1.6.4"
  gem 'mods'

  # Need rubyracer to run integration tests.....really?!?
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby
  gem 'method_decorators'
  gem 'rabl'
end

group :headless do
  gem 'clamav'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'bootstrap-sass', '~> 2.2.0'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass-rails'
  gem 'sass-rails',   '~> 3.2.3'
  gem 'uglifier', '>= 1.0.3'
  gem 'font-awesome-sass-rails', '~> 2.0.0.0'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'rspec-html-matchers'
  gem 'rspec-rails'
  gem 'webmock'
end

group :test, :development do
  gem 'debugger', ">= 1.4"
  gem 'rails_best_practices'
  gem 'guard', :require => false
  gem 'guard-rails_best_practices'
  gem 'guard-rspec', :require => false
  gem 'guard-spork'
  gem 'sextant'
  gem 'simplecov'
  gem 'method_locator'
  gem 'spork', '~> 1.0rc'
  gem 'ruby_gntp'
  gem 'sqlite3'
end

group :deploy do
  gem 'capistrano'
end
