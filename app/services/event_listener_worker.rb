class EventListenerWorker
  include java.util.concurrent.Callable

  def initialize job, logger
    @event_params = job.body['data']
    @logger = logger
  end

  def call
    event = Event.create @event_params
    @logger.info('EventListenerDaemon') { "Recently created event #{event.id} with action #{event.event}" }
    ApiEventListener.logger.info('Tracker') { "Recently created event #{event.id} with action #{event.event}" }
  end
end