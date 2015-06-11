require 'spec_helper'

describe Restfully::Session do
  before do
    RestClient.components.clear
    @logger = Logger.new(STDERR)
    @uri = "https://api.project.net"
    @config = {
      :uri => @uri,
      :logger => @logger
    }
  end

  describe "intialization" do
    it "should initialize a session with the correct properties" do
      session = Restfully::Session.new(@config.merge("key" => "value"))
      session.logger.should == @logger
      session.uri.should == Addressable::URI.parse(@uri)
      session.config.to_hash.values_at(:wait_before_retry, :key, :retry_on_error).should == [5, "value", 5]
    end

    it "should set a default URI if no URI given" do
      session = Restfully::Session.new(@config.merge(:uri => ""))
      session.uri.to_s.should == Restfully::DEFAULT_URI
    end
    
    it "should set en empty hash for ssl_options if none given" do
      session = Restfully::Session.new(@config.merge("key" => "value"))
      session.ssl_options.should == {}
    end

    it "should keep ssl_options if some given" do
      ssl_options={:verify_ssl => true, :ssl_option => 3}
      session = Restfully::Session.new(@config.merge(ssl_options))
      session.ssl_options.should == ssl_options
    end

    it "should add or replace additional headers to the default set" do
      session = Restfully::Session.new(
        @config.merge(:default_headers => {
          'Accept' => 'application/xml',
          'Cache-Control' => 'no-cache'
        })
      )
      session.default_headers.should == {
        'Accept' => 'application/xml',
        'Cache-Control' => 'no-cache',
        'Accept-Encoding' => 'gzip, deflate',
        'User-Agent' => "Restfully/#{Restfully::VERSION}" 
      }
    end
    
    it "should pass configuration options to Rack::Cache" do
      session = Restfully::Session.new(@config.merge({
        :cache => {
          :metastore   => 'file:/var/cache/rack/meta',
          :entitystore => 'file:/var/cache/rack/body'
        }
      }))
      RestClient.components.should == [[Rack::Cache, [{
        :verbose => true,
        :metastore   => 'file:/var/cache/rack/meta',
        :entitystore => 'file:/var/cache/rack/body'
      }]]]
    end
    
    it "should disable the client-side cache if given :no_cache" do
      session = Restfully::Session.new(@config.merge({
        :cache => false
      }))
      RestClient.components.should == []
    end
  end

  it "should fetch the root path [no URI path]" do
    session = Restfully::Session.new(@config)
    session.should_receive(:get).with("").
      and_return(res = mock(Restfully::Resource))
    res.should_receive(:load).and_return(res)
    session.root.should == res
  end
  
  it "should return a sanbox" do
    session = Restfully::Session.new(@config)
    sandbox = session.sandbox
    sandbox.session.should == session
    sandbox.logger.should == session.logger
  end

  it "should fetch the root path [URI path present]" do
    session = Restfully::Session.new(
      @config.merge(:uri => "https://api.project.net/resource/path")
    )
    session.should_receive(:get).with("/resource/path").
      and_return(res = mock(Restfully::Resource))
    res.should_receive(:load).and_return(res)
    session.root.should == res
  end

  describe "middleware" do
    it "should only have Rack::Cache enabled by default" do
      session = Restfully::Session.new(@config)
      session.middleware.length.should == 1
      session.middleware.should == [
        Rack::Cache
      ]
    end

    it "should use Restfully::Rack::BasicAuth if basic authentication is used" do
      session = Restfully::Session.new(@config.merge(
        :username => "crohr", :password => "p4ssw0rd"
      ))
      session.middleware.length.should == 2
      session.middleware.should == [
        Rack::Cache,
        Restfully::Rack::BasicAuth
      ]
    end
  end

  describe "transmitting requests" do
    before do
      @session = Restfully::Session.new(@config)
      @path = "/path"
      @default_headers = @session.default_headers
    end

    it "should make a get request" do
      stub_request(:get, @uri+@path+"?k1=v1&k2=v2").with(
        :headers => @default_headers.merge({
          'Accept' => '*/*',
          'X-Header' => 'value'
        })
      ).to_return(
        :status => 200,
        :body => 'body',
        :headers => {'X'=>'Y'}
      )

      Restfully::HTTP::Response.should_receive(:new).with(
        @session, 200, hash_including({'X'=>'Y'}), ['body']
      ).and_return(
        @response = mock(Restfully::HTTP::Response)
      )

      @session.should_receive(:process).with(
        @response,
        instance_of(Restfully::HTTP::Request)
      )

      @session.send(:transmit, :get, @path, {
        :query => {:k1 => "v1", :k2 => "v2"},
        :headers => {'X-Header' => 'value'}
      })
    end

    it "should make an authenticated get request" do
      stub_request(:get, "https://crohr:p4ssw0rd@api.project.net"+@path+"?k1=v1&k2=v2").with(
        :headers => @default_headers.merge({
          'Accept' => '*/*',
          'X-Header' => 'value'
        })
      )
      @session.should_receive(:process)
      @session.authenticate :username => 'crohr', :password => 'p4ssw0rd'
      @session.send(:transmit, :get, @path, {
        :query => {:k1 => "v1", :k2 => "v2"},
        :headers => {'X-Header' => 'value'}
      })
    end

    it "should retry for at most :max_attempts_on_connection_error if connection to the server failed" do

    end
  end

  describe "processing responses" do
    before do
      @session = Restfully::Session.new(@config)
      @request = Restfully::HTTP::Request.new(
        @session,
        :get,
        @uri
      )
      @request.stub!(:head).and_return({})
      @request.stub!(:update!).and_return(nil)
      
      @response = Restfully::HTTP::Response.new(
        @session,
        200,
        {'X' => 'Y', 'Content-Type' => 'text/plain'},
        'body'
      )
    end

    it "should return true if status=204" do
      @response.stub!(:code).and_return(204)
      @session.process(@response, @request).should be_true
    end

    it "should raise a Restfully::HTTP::ClientError if status in 400..499" do
      @response.stub!(:code).and_return(400)
      lambda{
        @session.process(@response, @request)
      }.should raise_error(Restfully::HTTP::ClientError)
    end

    it "should raise a Restfully::HTTP::ServerError if status in 500..599" do
      @response.stub!(:code).and_return(500)
      lambda{
        @session.process(@response, @request)
      }.should raise_error(Restfully::HTTP::ServerError)
    end
    it "should retry if the server returns one of [502,503,504], and request.retry! returns a response" do
      @request.should_receive(:retry!).once.
        and_return(@response)
      @response.should_receive(:code).ordered.and_return(503)
      @response.should_receive(:code).ordered.and_return(200)
      @session.process(@response, @request)
    end
    it "should not retry if the server returns one of [502,503,504], but request.retry! returns false" do
      @request.should_receive(:retry!).once.
        and_return(false)
      @response.stub!(:code).and_return(503)
      lambda{
        @session.process(@response, @request)
      }.should raise_error(Restfully::HTTP::ServerError, /503/)
    end

    it "should raise an error if the status is not supported" do
      @response.stub!(:code).and_return(50)
      lambda{
        @session.process(@response, @request)
      }.should raise_error(Restfully::Error)
    end

    [301, 302].each do |status|
      it "should fetch the resource specified in the Location header if status = #{status}" do
        @response.stub!(:code).and_return(status)
        @response.head['Location'] = @uri+"/path"

        @session.should_receive(:get).
          with(@uri+"/path", :head => @request.head).
          and_return(resource=mock("resource"))
        @session.process(@response, @request).
          should == resource
      end
    end

    it "should return a Restfully::Resource if successful" do
      Restfully::MediaType.register Restfully::MediaType::ApplicationJson
      body = {
        :key1 => "value1",
        :key2 => ["value2", "value3"]
      }
      @response = Restfully::HTTP::Response.new(
        @session, 200,
        {'Content-Type' => 'application/json'},
        JSON.dump(body)
      )

      resource = @session.process(
        @response,
        @request
      )

      resource.should be_a(Restfully::Resource)
      resource.uri.should == @request.uri
      resource['key1'].should == body[:key1]
      resource['key2'].should == body[:key2]
    end

    it "should raise an error if the response content-type is not supported" do
      @response = Restfully::HTTP::Response.new(
        @session, 200,
        {'Content-Type' => ''},
        'body'
      )

      lambda{
        @session.process(@response,@request)
      }.should raise_error(
        Restfully::Error,
        "Cannot find a media-type for content-type=\"\""
      )
    end
  end

end

