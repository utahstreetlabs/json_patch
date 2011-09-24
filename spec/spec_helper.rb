require 'rubygems'
require 'bundler'

Bundler.setup

require 'rspec'
require 'mocha'
require 'json/patch'

RSpec.configure do |config|
  config.mock_with :mocha
end
