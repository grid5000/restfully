require File.expand_path(File.dirname(__FILE__)+'/spec_helper')
restfully_version = File.read(File.dirname(__FILE__)+'/../VERSION').strip

include Restfully
describe Session do
  before do
    @session = Session.new(:base_uri => 'https://api.grid5000.fr/sid/', :user => 'crohr', :password => 'password', :default_headers => {})
    @request = mock("restfully http request", :uri => mock("uri"), :headers => mock("headers"), :body => nil)
    @response = mock("restfully http response", :status => 200, :headers => mock("headers"))
  end
  describe "initialization" do
    it "should have a logger reader" do
      session = Session.new(:base_uri => 'https://api.grid5000.fr')
      session.should_not respond_to(:logger=)
      session.should respond_to(:logger)
    end
    it "should have a base_uri reader" do
      session = Session.new(:base_uri => 'https://api.grid5000.fr')
      session.should_not respond_to(:base_uri=)
      session.base_uri.should == URI.parse('https://api.grid5000.fr')
    end
    it "should raise an ArgumentError if the base_uri is not a valid URI" do
      lambda{Session.new(:base_uri => '/home/crohr/whatever')}.should raise_error(ArgumentError, /\/home\/crohr\/whatever is not a valid URI/)
    end
    it "should log to NullLogger by default" do
      NullLogger.should_receive(:new).and_return(logger = mock(NullLogger, :debug => Proc.new{}, :level => Logger::WARN))
      logger.should_receive(:level=).with(Logger::WARN)
      session = Session.new(:base_uri => 'https://api.grid5000.fr')
      session.logger.should == logger
    end
    it "should use the given logger" do
      logger = mock("custom logger", :debug => Proc.new{})
      logger.should_receive(:level=).with(Logger::DEBUG)
      session = Session.new(:base_uri => 'https://api.grid5000.fr', 'logger' => logger, :verbose => true)
      session.logger.should == logger
    end
    it "should set a default Accept HTTP header if no default headers are given" do
      session = Session.new(:base_uri => 'https://api.grid5000.fr')
      session.default_headers.should == {
        "User-Agent"=>"Restfully/#{restfully_version}",
        'Accept' => 'application/json'
      }
    end
    it "should use the given default headers" do
      session = Session.new(:base_uri => 'https://api.grid5000.fr', :default_headers => {:accept => 'application/xml'})
      session.default_headers.should == {
        "User-Agent"=>"Restfully/#{restfully_version}",
        "Accept" => 'application/xml'
      }
    end
    it "should correctly initialize the connection" do
      mock_logger = mock("logger", :debug => Proc.new{}, :level => Logger::DEBUG)
      mock_logger.stub!(:level=)
      Restfully.adapter.should_receive(:new).with('https://api.grid5000.fr/sid', :user => 'crohr', :password => 'password', :logger => mock_logger).and_return(connection = mock("restfully connection"))
      session = Session.new(:base_uri => 'https://api.grid5000.fr/sid', :user => 'crohr', :password => 'password', :logger => mock_logger)
      session.connection.should == connection
    end
  
    it "should initialize the root resource" do
      session = Session.new(:base_uri => 'https://api.grid5000.fr/grid5000', :user => 'crohr', :password => 'password')
      session.root.should be_a Restfully::Resource
      session.root.uri.to_s.should == 'https://api.grid5000.fr/grid5000'
      session.root.uri.path.should == '/grid5000'
    end
  
    it "should yield the loaded root resource and the session object" do
      Restfully::Resource.stub!(:new).and_return(root_resource = mock(Restfully::Resource))
      root_resource.should_receive(:load).and_return(root_resource)
      Session.new(:base_uri => 'https://api.grid5000.fr', :user => 'crohr', :password => 'password') do |root, session|
        session.root.should == root
        root.should == root_resource
      end
    end
    
    it "should use the options defined in the given configuration file" do
      config_file = 
      session = Session.new(:base_uri => 'https://api.grid5000.fr', :username => 'x', :password => 'y', :verbose => true, :configuration_file => (File.dirname(__FILE__)+'/fixtures/configuration_file.yml'))
      session.base_uri.should == URI.parse('http://somewhere.net/x/y/z')
      session.logger.should_not == Logger::DEBUG
    end
  end
  
  describe "Transmitting requests" do
    before do
      Session.send(:public, :transmit)  
      @request.headers.stub!(:[]).and_return(nil)
      @request.headers.should_receive(:[]=).with("User-Agent", "Restfully/#{restfully_version}")
      @request.headers.should_receive(:[]=).with("Accept", "application/json")
    end
    it "should send a head" do
      @session.connection.should_receive(:head).with(@request).and_return(@response)
      @session.should_receive(:deal_with_eventual_errors).with(@response, @request).and_return(@response)
      @session.send(:transmit, :head, @request).should == @response
    end
    it "should send a get" do
      @session.connection.should_receive(:get).with(@request).and_return(@response)
      @session.should_receive(:deal_with_eventual_errors).with(@response, @request).and_return(@response)
      @session.send(:transmit, :get, @request).should == @response
    end
    it "should send a post" do
      @session.connection.should_receive(:post).with(@request).and_return(@response)
      @session.should_receive(:deal_with_eventual_errors).with(@response, @request).and_return(@response)
      @session.send(:transmit, :post, @request).should == @response
    end
  end
  
  describe "URI construction" do
    it "should not use the base_uri if the given path is a complete URI" do
      @session.uri_for('http://somehost.com/some/path').should == URI.parse('http://somehost.com/some/path')
    end
    it "should combine the base_uri with the given path (absolute) if it is not a complete URI" do
      @session.uri_for('/some/path').should == URI.parse('https://api.grid5000.fr/some/path')
    end
    it "should combine the base_uri with the given path (relative) if it is not a complete URI" do
      @session.uri_for('some/path').should == URI.parse('https://api.grid5000.fr/sid/some/path')
    end
  end
  
  describe "Dealing with errors" do   
    before do      
      Session.send(:public, :deal_with_eventual_errors)
    end 
    it "should raise a Restfully::HTTP::ClientError error on 4xx errors" do
      response = mock("404 response", :status => 404, :body => {'code' => 404, 'message' => 'The requested resource cannot be found.', 'title' => 'Not Found'}, :headers => mock("headers"))
      lambda{ @session.send(:deal_with_eventual_errors, response, @request) }.should raise_error(Restfully::HTTP::ClientError, "404 Not Found. The requested resource cannot be found.")
    end
    
    it "should raise a Restfully::HTTP::ServerError error on 5xx errors" do
      response = mock("500 response", :status => 500, :body => {'code' => 500, 'message' => 'Something went wrong.', 'title' => 'Internal Server Error'}, :headers => mock("headers"))
      lambda{ @session.send(:deal_with_eventual_errors, response, @request) }.should raise_error(Restfully::HTTP::ServerError, "500 Internal Server Error. Something went wrong.")
    end
  end
  
  describe "HEADing resources" do
    it "should create a new Request object and transmit it" do
      Restfully::HTTP::Request.should_receive(:new).with(URI.parse('https://api.grid5000.fr/sid/some/path'), :headers => nil, :query => nil).and_return(@request)
      @session.should_receive(:transmit).with(:head, @request)
      @session.head('some/path')
    end
  end
  
  describe "GETting resources" do
    it "should create a new Request object and transmit it" do
      Restfully::HTTP::Request.should_receive(:new).with(URI.parse('https://api.grid5000.fr/sid/some/path'), :headers => {:cache_control => 'max-age=0'}, :query => nil).and_return(@request)
      @session.should_receive(:transmit).with(:get, @request)
      @session.get('some/path', 'headers' => {:cache_control => 'max-age=0'})
    end
  end
  
  describe "POSTing payload" do
    it "should create a new Request object with a body, and transmit it" do
      Restfully::HTTP::Request.should_receive(:new).with(URI.parse('https://api.grid5000.fr/sid/some/path'), :body => '{"a":"b"}', :headers => {:content_type => 'application/json'}, :query => nil).and_return(@request)
      @session.should_receive(:transmit).with(:post, @request)
      @session.post('some/path', {"a" => "b"}.to_json, 'headers' => {:content_type => 'application/json'})
    end
  end
  
  describe "DELETEing resources" do
    it "should create a new Request object and transmit it" do
      Restfully::HTTP::Request.should_receive(:new).with(URI.parse('https://api.grid5000.fr/sid/some/path'), :headers => {:accept => 'application/json'}, :query => nil).and_return(@request)
      @session.should_receive(:transmit).with(:delete, @request)
      @session.delete('some/path', 'headers' => {:accept => 'application/json'})
    end
  end
  
end