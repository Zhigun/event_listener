RSpec.describe EventListener do
  before do
    described_class.configure { |c| c.logger = Logger.new(nil) }
    @valid_job = { 'data' => {'user_uri' => 'user:123456', 'created_at' => DateTime.now, 'event' => 'rspec_test'}}
    @invalid_job =  {user_uri: 'user:123456'}
    @invalid_job_without_user_uri = { 'data' => {'created_at' => DateTime.now, 'event' => 'rspec_test'}}
    @invalid_job_without_date    = { 'data' => {'user_uri' => 'user:123456','event' => 'rspec_test'}}
  end

  describe 'configuration' do
    it 'should have default configuration' do
      instance1 = described_class.new
      expect(instance1.beanstalk_host).to eq('localhost')
      expect(instance1.workers).to eq(10)
      expect(instance1.tube_name).to eq('event_listener')
    end

    it 'should accept configuration for all instances' do
      described_class.configure do |c|
        c.beanstalk_host = 'localhost:11300'
        c.tube_name      = 'mailer_test'
        c.logger = Logger.new(nil)
      end
      instance1 = described_class.new
      instance2 = described_class.new
      expect(instance1.beanstalk_host).to eq(instance2.beanstalk_host)
      described_class.reset
    end
  end

  describe 'work processing' do
    before(:each) do
      described_class.configure { |c| c.logger = Logger.new(nil) }
      @instance = described_class.new
    end

    it 'should log error and reconnect if beaneater not available' do
      allow_any_instance_of(Beaneater::Tubes).to receive(:reserve).and_raise(Beaneater::NotConnected)
      expect(@instance.logger).to receive(:warn) do |tag, &message|
        expect(tag).to eq('EventListenerDaemon')
        expect(message.call).to eq('Lost connection to Beanstalk, reconnecting...')
      end
      expect(@instance).to receive(:init_connection)
      @instance.process_cycle
    end

    it 'should create instance of EventListenerWorker on job submit and call it' do
      allow_any_instance_of(Hash).to receive(:body).and_return(@valid_job)
      worker_stub = double('EventListenerWorker')
      allow_any_instance_of(Beaneater::Tubes).to receive(:reserve).and_return(@valid_job)
      expect(EventListenerWorker).to receive(:new).with(@valid_job, described_class.job_logger).and_return(worker_stub)
      expect(worker_stub).to receive(:call)
      @instance.process_cycle
    end

    context 'checking job for errors' do
      it 'should return correct errors for invalid job without data' do
        allow_any_instance_of(Hash).to receive(:body).and_return(@invalid_job)
        expect { @instance.check @invalid_job }.to raise_error(EventListener::MalformedJob, 'data')
      end

      it 'should return correct errors for job without user_uri' do
        allow_any_instance_of(Hash).to receive(:body).and_return(@invalid_job_without_user_uri)
        expect { @instance.check @invalid_job_without_user_uri }.to raise_error(EventListener::MalformedJob, 'user_uri')
      end

      it 'should return correct errors for job without date' do
        allow_any_instance_of(Hash).to receive(:body).and_return(@invalid_job_without_date)
        expect { @instance.check @invalid_job_without_date }.to raise_error(EventListener::MalformedJob, 'created_at')
      end

      it 'should log error if job is malformed' do
        allow_any_instance_of(Beaneater::Tubes).to receive(:reserve).and_return(@invalid_job)
        expect(described_class.logger).to receive(:error).with('EventListenerDaemon')
        @instance.process_cycle
      end
    end
  end

end