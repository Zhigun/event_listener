class Event
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :user_uri,   type: String
  field :created_at, type: DateTime

  validates_presence_of :user_uri, :created_at
end
