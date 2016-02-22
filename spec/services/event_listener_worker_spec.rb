RSpec.describe EventListenerWorker do
 describe 'workflow' do
   it 'creates event' do
     job = { 'data' => {'user_uri' => 'user:123456', 'created_at' => DateTime.now, 'event' => 'rspec_test'}}
     allow(job).to receive(:body).and_return(job)
     instance = described_class.new job, Logger.new(nil)
     expect{instance.call}.to change{Event.count}.by(1)
   end
 end
end