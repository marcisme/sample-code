require 'rack/test'
require 'sinatra'
require 'rspec'
require 'warden'

# model
class User
  attr_reader :id
  attr_reader :name
  def initialize(name)
    @id = 1 # please don't really do this
    @name = name
  end
end

# modular sinatra app
class Greeter < Sinatra::Base
  get '/' do
    "Hello, #{request.env['warden'].user.name}"
  end
end

# tests
describe Greeter do
  include Rack::Test::Methods
  include Warden::Test::Helpers

  after(:each) do
    Warden.test_reset!
  end

  def app
    Rack::Builder.new do
      # these serialization methods don't do anything in this example,
      # but they could be necessary depending on the app you're testing
      Warden::Manager.serialize_into_session { |user| user.id }
      Warden::Manager.serialize_from_session { |id| User.get(id) }
      # your session middleware needs to come before warden
      use Rack::Session::Cookie
      use Warden::Manager
      run Greeter
    end
  end

  it 'says hi to me' do
    login_as User.new('Marc')
    get '/'
    last_response.body.should == 'Hello, Marc'
  end
end
