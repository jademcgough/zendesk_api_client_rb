require 'core/spec_helper'

describe ZendeskAPI::Rescue do
  include ZendeskAPI::Rescue

  class Boom
    include ZendeskAPI::Rescue
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def puff(error)
      if error.is_a?(Class)
        raise error, "Puff"
      else
        raise error
      end
    end

    def boom(error)
      raise error, "Boom"
    end

    rescue_client_error :puff
  end

  it "rescues from client errors", :silence_logger do
    Boom.new(client).puff(Faraday::Error::ClientError)
  end

  it "does not protect other actions" do
    expect{
      Boom.new(client).boom(RuntimeError)
    }.to raise_error RuntimeError
  end

  it "raises everything else" do
    expect{
      Boom.new(client).puff(RuntimeError)
    }.to raise_error RuntimeError
  end

  it "logs to logger" do
    out = StringIO.new
    client = ZendeskAPI::Client.new do |config|
      config.logger = Logger.new(out)
      config.url = "https://idontcare.com"
    end
    out.should_receive(:write).at_least(:twice)
    Boom.new(client).puff(Faraday::Error::ClientError)
  end

  it "does crash without logger" do
    client = ZendeskAPI::Client.new do |config|
      config.logger = false
      config.url = "https://idontcare.com"
    end
    Boom.new(client).puff(Faraday::Error::ClientError)
  end

  context "when class has error attributes", :silence_logger do
    let(:response) {{ :body => { :error => { :description => "hello" } } }}
    let(:instance) { Boom.new(client) }

    before do
      Boom.send(:attr_accessor, :error, :error_message)

      exception = Exception.new("message")
      exception.set_backtrace([])

      error = Faraday::Error::ClientError.new(exception, response)
      instance.puff(error)
    end

    it "should attach the error" do
      instance.error.should_not be_nil
    end
  end

  context "passing a block" do
    it "rescues from client errors", :silence_logger do
      rescue_client_error do
        raise Faraday::Error::ClientError, "error"
      end
    end

    it "raises everything else" do
      expect{
        rescue_client_error { raise RuntimeError, "error" }
      }.to raise_error RuntimeError
    end

    it "logs to logger" do
      out = StringIO.new
      @client = ZendeskAPI::Client.new do |config|
        config.logger = Logger.new(out)
        config.url = "https://idontcare.com"
      end
      out.should_receive(:write).at_least(:twice)
      rescue_client_error do
        raise Faraday::Error::ClientError, "error"
      end
    end

    it "does crash without logger" do
      @client = ZendeskAPI::Client.new do |config|
        config.logger = false
        config.url = "https://idontcare.com"
      end
      rescue_client_error do
        raise Faraday::Error::ClientError, "error"
      end
    end
  end
end
