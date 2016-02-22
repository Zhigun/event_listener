class EventListener
  class << self
    attr_accessor :beanstalk_host, :tube_name, :logger, :job_logger, :workers

    DEFAULT_LOGGER_OUTPUT = if ApiEventListener.test?
      STDOUT
    else
      STDOUT
    end

    def configure
      reset
      yield self if block_given?
    end

    def reset
      self.workers = 10
      self.beanstalk_host = 'localhost'
      self.tube_name = 'event_listener'
      self.logger = Logger.new(DEFAULT_LOGGER_OUTPUT)
      self.job_logger = Logger.new(DEFAULT_LOGGER_OUTPUT)
    end
  end
end

EventListener.configure
