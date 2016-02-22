$:.unshift File.expand_path('../../app', __FILE__)
ENV['RACK_ENV'] ||= 'development'

require File.expand_path('../boot', __FILE__)

Bundler.require :default, ENV['RACK_ENV']

module ApiEventListener
  class << self
    def root
      @root ||= File.expand_path('../../.', __FILE__)
    end

    def env
      @env ||= ENV['RACK_ENV']
    end

    def logger
      @logger ||= Logger.new(File.join(File.expand_path("../../log/#{ApiEventListener.env}.log", __FILE__)))
    end

    %w(development test qa production).each do |e|
      define_method "#{e}?".to_sym do
        return env == e.to_s
      end
    end
  end
end

# an unhandleable error that results in a program crash
Mongoid.logger.level = 4

Beaneater.configure do |config|
  config.job_parser = lambda { |body| JSON.parse(body)}
end

Dir[File.join(ApiEventListener.root, 'app/models/*.rb')].each do |f|
  require f
end

Dir[File.join(ApiEventListener.root, 'config/initializers/*.rb')].each do |f|
  require f
end

