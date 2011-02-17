require 'spec_helper'

describe Restfully::Session do
  before do
    RestClient.components.clear
    @logger = Logger.new(STDERR)
    @uri = "https://api.grid5000.fr"
    @config = {
      :uri => @uri,
      :logger => @logger
    }
  end
  
  it "should initialize a session with the correct properties" do
    session = Restfully::Session.new(@config.merge("key" => "value"))
    session.logger.should == @logger
    session.uri.should == URI.parse(@uri)
    session.config.should == {:key => "value"}
  end
  
  it "should raise an error if no URI given" do
    lambda{
      Restfully::Session.new(@config.merge(:uri => ""))
    }.should raise_error(ArgumentError)
  end
  
  it "should fetch the root path [no URI path]" do
    session = Restfully::Session.new(@config)
    session.should_receive(:get).with("").
      and_return(res = mock(Restfully::Resource))
    res.should_receive(:load).and_return(res)
    session.root.should == res
  end
  
  it "should fetch the root path [URI path present]" do
    session = Restfully::Session.new(
      @config.merge(:uri => "https://api.grid5000.fr/resource/path")
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
      
      @session.transmit :get, @path, {
        :query => {:k1 => "v1", :k2 => "v2"},
        :headers => {'X-Header' => 'value'}
      }
    end
    
    it "should make an authenticated get request" do
      stub_request(:get, "https://crohr:p4ssw0rd@api.grid5000.fr"+@path+"?k1=v1&k2=v2").with(
        :headers => @default_headers.merge({
          'Accept' => '*/*',
          'X-Header' => 'value'
        })
      )
      @session.should_receive(:process)
      @session.authenticate :username => 'crohr', :password => 'p4ssw0rd'
      @session.transmit :get, @path, {
        :query => {:k1 => "v1", :k2 => "v2"},
        :headers => {'X-Header' => 'value'}
      }
    end
  end
  
  describe "processing responses" do
    before do
      @session = Restfully::Session.new(@config)
      @request = mock(
        Restfully::HTTP::Request, 
        :method => :get, 
        :uri => @uri, 
        :head => mock("head")
      )
      @response = Restfully::HTTP::Response.new(
        @session,
        200,
        {'X' => 'Y'},
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
    
    it "should raise an error if the status is not supported" do
      @response.stub!(:code).and_return(50)
      lambda{
        @session.process(@response, @request)
      }.should raise_error(Restfully::Error)
    end
    
    [201, 202].each do |status|
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

