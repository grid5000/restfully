require File.dirname(__FILE__)+'/spec_helper'

include Restfully
describe Session do
  describe "initialization" do
    it "should have a logger reader" do
      session = Session.new('https://api.grid5000.fr')
      session.should_not respond_to(:logger=)
      session.should respond_to(:logger)
    end
    it "should have a base_url reader" do
      session = Session.new('https://api.grid5000.fr')
      session.should_not respond_to(:base_url=)
      session.base_url.should == 'https://api.grid5000.fr'
    end
    it "should have a relative_root_uri reader that returns the URI of the root resource, relative to the base URL" do
      session = Session.new('https://api.grid5000.fr/sid', 'relative_root_uri' => '/grid5000')
      session.should_not respond_to(:relative_root_uri=)
      session.relative_root_uri.should == '/grid5000'
    end
    it "should set the default relative_root_uri to /" do
      session = Session.new('https://api.grid5000.fr')
      session.relative_root_uri.should == '/'
    end
    it "should log to NullLogger by default" do
      NullLogger.should_receive(:new).and_return(logger = mock(NullLogger))
      session = Session.new('https://api.grid5000.fr')
      session.logger.should == logger
    end
    it "should use the given logger" do
      logger = mock("custom logger")
      session = Session.new('https://api.grid5000.fr', 'logger' => logger)
      session.logger.should == logger
    end
    it "should set a default Accept HTTP header if no default headers are given" do
      session = Session.new('https://api.grid5000.fr')
      session.default_headers.should == {
        'Accept' => 'application/json'
      }
    end
    it "should use the given default headers" do
      session = Session.new('https://api.grid5000.fr', :default_headers => {:accept => 'application/xml'})
      session.default_headers.should == {
        :accept => 'application/xml'
      }
    end
    it "should correctly initialize the connection" do
      Restfully.adapter.should_receive(:new).with('https://api.grid5000.fr/sid', :user => 'crohr', :password => 'password').and_return(connection = mock("restfully connection"))
      session = Session.new('https://api.grid5000.fr/sid', 'relative_root_uri' => '/grid5000', :user => 'crohr', :password => 'password')
      session.connection.should == connection
    end
  
    it "should initialize the root resource" do
      session = Session.new('https://api.grid5000.fr', 'relative_root_uri' => '/grid5000', :user => 'crohr', :password => 'password')
      session.root.should be_a Restfully::Resource
      session.root.uri.to_s.should == '/grid5000'
      session.root.should_not be_loaded
    end
  
    it "should yield the loaded root resource and the session object" do
      Restfully::Resource.stub!(:new).and_return(root_resource = mock(Restfully::Resource))
      root_resource.should_receive(:load).and_return(root_resource)
      Session.new('https://api.grid5000.fr', :relative_root_uri => '/grid5000', :user => 'crohr', :password => 'password') do |root, session|
        session.root.should == root
        root.should == root_resource
      end
    end
  end
  
  describe "Getting resources" do
    before(:each) do
      @session = Session.new('https://api.grid5000.fr/sid', :relative_root_uri => '/grid5000', :user => 'crohr', :password => 'password', :default_headers => {})
      @request = mock("restfully http request")
      @response = mock("restfully http response", :status => 200)
    end
    it "should create a new Request object and pass it to the connection" do
      Restfully::HTTP::Request.should_receive(:new).with(URI.parse('https://api.grid5000.fr/sid/some/path'), :headers => {:cache_control => 'max-age=0'}, :query => {}).and_return(@request)
      @session.connection.should_receive(:get).with(@request).and_return(@response)
      @session.get('/some/path', :headers => {:cache_control => 'max-age=0'}).should == @response
    end
    it "should not use the base_url if the path is a complete url" do
      Restfully::HTTP::Request.should_receive(:new).with(URI.parse('http://somehost.com/some/path'), :headers => {}, :query => {}).and_return(@request)
      @session.connection.should_receive(:get).with(@request).and_return(@response)
      @session.get('http://somehost.com/some/path').should == @response
    end
    it "should add the session's default headers to the request's headers" do
      Restfully::HTTP::Request.should_receive(:new).with(URI.parse('http://somehost.com/some/path'), :headers => {}, :query => {}).and_return(@request)
      @session.default_headers['cache-control'] = 'max-age=0'
      @request.should_receive(:add_headers).with('cache-control' => 'max-age=0')
      @session.connection.should_receive(:get).with(@request).and_return(@response)
      @session.get('http://somehost.com/some/path').should == @response
    end
    it "should raise a Restfully::HTTP::ClientError error on 4xx errors" do
      Restfully::HTTP::Request.should_receive(:new).with(URI.parse('http://somehost.com/some/path'), :headers => {}, :query => {}).and_return(@request)
      @session.connection.should_receive(:get).with(@request).and_return(response = mock("404 response", :status => 404, :body => {'code' => 404, 'message' => 'The requested resource cannot be found.', 'title' => 'Not Found'}))
      lambda{ @session.get('http://somehost.com/some/path') }.should raise_error(Restfully::HTTP::ClientError, "404 Not Found. The requested resource cannot be found.")
    end
    it "should raise a Restfully::HTTP::ServerError error on 4xx errors" do
      Restfully::HTTP::Request.should_receive(:new).with(URI.parse('http://somehost.com/some/path'), :headers => {}, :query => {}).and_return(@request)
      @session.connection.should_receive(:get).with(@request).and_return(response = mock("404 response", :status => 500, :body => {'code' => 500, 'message' => 'Something went wrong.', 'title' => 'Internal Server Error'}))
      lambda{ @session.get('http://somehost.com/some/path') }.should raise_error(Restfully::HTTP::ServerError, "500 Internal Server Error. Something went wrong.")
    end
  end
  
end