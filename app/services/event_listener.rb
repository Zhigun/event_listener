require File.expand_path('../../../config/app', __FILE__)
require 'services/event_listener_worker'

java_import 'java.util.concurrent.Executors'

class EventListener
  class MalformedJob < StandardError; end;

  attr_accessor :beanstalk_host, :tube_name, :logger, :job_logger, :workers

  def initialize args = {}
    logger.warn('EventListener') { 'INITIALIZER' }
    init_thread_pool
    init_connection
  end

  def init_thread_pool
    @executors = Executors::newFixedThreadPool workers
  end

  def init_connection
    logger.info('EventListenerDaemon') { 'Starting service...' }
    @bt = Beaneater.new Array.wrap(beanstalk_host)
    @bt.tubes.watch! *[tube_name]
    logger.info('EventListenerDaemon') { "Listening to #{tube_name} tube on #{Array.wrap(beanstalk_host).join(',')}" }
  end

  def start
    logger.warn('EventListener') { 'STARTING SERVICE' }
    @processing = true
    @thread = Thread.new { while @processing do process_cycle; end }
  end

  def process_cycle
    job = @bt.tubes.reserve
    check job
    work job
    job.delete
  rescue Beaneater::NotConnected
    logger.warn('EventListenerDaemon') { 'Lost connection to Beanstalk, reconnecting...' }
    init_connection
  rescue MalformedJob => e
    job.bury
    logger.error('EventListenerDaemon') { "Received malformed message(s) #{e.message} " }
  rescue Exception => e
    logger.error('EventListenerDaemon') { "Listener got exception:\n#{e}" }
  end


  def stop
    @processing = false
    @executors.shutdown
    @thread.kill
  end

  def check job
    body = job.body
    messages = []
    raise MalformedJob.new('data') unless body.is_a?(Hash) && body.keys.include?('data')
    messages << 'user_uri'         unless body['data'] && body['data'].keys.include?('user_uri')
    messages << 'created_at'       unless body['data'] && body['data'].keys.include?('created_at')
    raise MalformedJob.new(messages.join(', ')) unless messages.blank?
  end

  def work job
    worker = EventListenerWorker.new(job, job_logger)
    if ApiEventListener.test?
      worker.call
    else
      @executors.submit worker
    end
  end

  def clear_tubes *tb_names
    tb_names.each do |name|
      tube = @bt.tubes[name]
      tube.clear
    end
  end

  def logger
    @logger ||= self.class.logger
  end

  def job_logger
    @job_logger ||= self.class.job_logger
  end

  def workers
    @workers ||= self.class.workers
  end

  def beanstalk_host
    binding.pry
    @beanstalk_host ||= self.class.beanstalk_host
  end

  def tube_name
    @tube_name ||= self.class.tube_name
  end

end