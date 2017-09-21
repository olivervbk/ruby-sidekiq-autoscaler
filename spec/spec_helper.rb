#ref http://stackoverflow.com/questions/4398262/setup-rspec-to-test-a-gem-not-rails
require 'bundler/setup'
Bundler.setup

require 'sidekiq_autoscaler'

require 'logger'

require 'rspec'
require 'rspec/collection_matchers'

RSpec.configure do |config|
#  config.color_enabled = true
  config.formatter     = 'documentation'
  #RAILS 5:config.file_fixture_path = "spec/example"
end
