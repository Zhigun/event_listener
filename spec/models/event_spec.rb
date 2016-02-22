RSpec.describe Event do
  it 'should check user_uri and created_at for presence' do
    instance = described_class.create(user_uri: 'user:123', created_at: DateTime.now)
    instance2 = described_class.create()
    expect(instance).to be_persisted
    expect(instance2).not_to be_persisted
    expect(instance2.errors.messages.keys).to eq([:user_uri, :created_at])
  end
end
