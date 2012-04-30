$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift(File.join(File.dirname(__FILE__), "macros"))

if RUBY_VERSION =~ /1.9/ && ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    add_filter "spec/"
  end
end

require 'zendesk'
require 'vcr'

require 'resource_macros'

RSpec.configure do |c|
  # so we can use `:vcr` rather than `:vcr => true`;
  # in RSpec 3 this will no longer be necessary.
  c.treat_symbols_as_metadata_keys_with_true_values = true

  c.before(:all, :vcr_off) do
    VCR.turn_off!
  end

  c.after(:all, :vcr_off) do
    VCR.turn_on!
  end

  c.extend VCR::RSpec::Macros
  c.extend ResourceMacros
end

VCR.configure do |c|
  c.cassette_library_dir = File.join(File.dirname(__FILE__), 'fixtures/cassettes')
  c.default_cassette_options = { :record => :new_episodes }
  c.hook_into :webmock
end

include WebMock::API

def client
  @client ||= Zendesk.configure do |config|
    config.username = "agent@zendesk.com"
    config.password = "123456"
    config.url = "http://dev.localhost:3000/api/v2"
    config.log = false 
    config.retry = true
  end
end

def user
  VCR.use_cassette('valid_user') do
    @user ||= client.users.first
  end
end

def current_user
  VCR.use_cassette('current_user') do
    @current_user ||= client.users.find('me') 
  end
end

def agent
  VCR.use_cassette('valid_agent') do
    @agent ||= client.users.detect {|u| u.role == "agent"}
  end
end

def topic
  VCR.use_cassette('valid_topic') do
    @topic ||= client.topics.first
  end
end

def forum
  VCR.use_cassette('valid_forum') do
    @forum ||= client.forums.first
  end
end

def category
  VCR.use_cassette('valid_category') do
    @category ||= client.categories.first
  end
end

def ticket
  VCR.use_cassette('valid_ticket') do
    @ticket ||= client.tickets.first
  end
end

def organization
  VCR.use_cassette('valid_organization') do
    @organization ||= current_user.organization 
  end
end

# Global default options, overwritten if using under
def default_options
  {}
end

class Zendesk::TestResource < Zendesk::Resource
  class TestChild < Zendesk::Resource
  end

  has_many :children, :class => :test_child
end

class Zendesk::NilResource < Zendesk::Data; end
