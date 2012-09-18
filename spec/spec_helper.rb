require File.dirname(__FILE__) + '/../lib/landscape'
require 'webmock/rspec'
require 'json'
require 'uri'
require 'timecop'


RSpec.configure do |config|
  config.order = 'random'
end

def load_fixture(fixture_name)
    File.open(File.dirname(__FILE__) + "/fixtures/#{fixture_name}.json")
end
