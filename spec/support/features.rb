# spec/support/features.rb
require File.expand_path('../fixture_helpers', __FILE__)

RSpec.configure do |config|
  config.include FixtureHelpers
end
