require 'rubygems'

ENV['RACK_ENV'] ||= 'test'

require 'database_cleaner'

require File.expand_path('../../config/environment', __FILE__)
require File.expand_path('../../app/services/event_listener',__FILE__)

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end


