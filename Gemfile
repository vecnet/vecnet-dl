source 'https://rubygems.org'

gem 'rails', '3.2.11'

gem 'mysql2'
gem 'common_repository_model', git: 'git://github.com/ndlib/common_repository_model'
gem 'sufia', git: 'git://github.com/ndlib/sufia.git', branch: 'sufia-for-curate-nd'
gem 'solrizer'#, git: 'git://github.com/ndlib/solrizer.git'
gem 'rsolr', git: 'git://github.com/jeremyf/rsolr.git', branch: 'adding-connection-information-to-error-handling'
gem 'jettywrapper'
gem 'jquery-rails'
gem 'decent_exposure'
gem 'devise_cas_authenticatable'
gem 'rake'
gem 'resque-pool'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'bootstrap-sass', '~> 2.2.0'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass-rails'
  gem 'sass-rails',   '~> 3.2.3'
  gem 'uglifier', '>= 1.0.3'
end

# Need rubyracer to run integration tests.....really?!?
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', :platforms => :ruby

group :test, :development, :ci do
  gem 'factory_girl_rails'
  gem 'rspec-rails'
  gem 'simplecov'
  gem 'debugger'
  gem 'database_cleaner'
  gem 'sextant'
  gem 'capybara'
  gem 'simplecov'
  gem 'rails_best_practices'
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'

gem "unicode", :platforms => [:mri_18, :mri_19]
gem "devise"
gem "devise-guests", "~> 0.3"
gem 'simple_form'

group :deploy do
  gem 'capistrano'
end
