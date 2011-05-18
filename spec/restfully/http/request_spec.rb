require 'spec_helper'

describe Restfully::HTTP::Request do
  before do
    @session = mock(
      Restfully::Session, 
      :default_headers => {
        'Accept' => '*/*; application/xml',
        :accept_encoding => "gzip, deflate"
      },
      :logger => Logger.new(STDERR),
      :config => {
        :retry_on_error => 5,
        :wait_before_retry => 5
      }
    )
    
    @options = {
      :head => {
        'Cache-control' => 'no-cache',
        :some_header => 'some value',
        'accept' => 'application/json'
      },
      :body => {:hello => 'world'}
    }
    
    @session.should_receive(:uri_to).with("/path").
      and_return(Addressable::URI.parse("https://api.grid5000.fr/path"))
  end
  
  it "should correctly build the request [no body]" do
    
    request = Restfully::HTTP::Request.new(@session, :get, "/path", @options)
    request.head.should == {
      'Cache-Control' => 'no-cache',
      'Some-Header' => 'some value',
      'Accept' => 'application/json',
      'Accept-Encoding' => 'gzip, deflate'
    }
    request.method.should == :get
  end
  
  it "should correctly add the query parameters to the URI" do
    @options[:query] = {:k1 => 'v1'}
    request = Restfully::HTTP::Request.new(@session, :get, "/path", @options)
    request.uri.to_s.should == "https://api.grid5000.fr/path?k1=v1"
  end
  
  it "should correctly update the request with the given parameters" do
    @options[:query] = {:k1 => 'v1', :k2 => [1,2,3]}
    @options[:head]['Accept'] = 'text/plain'
    request = Restfully::HTTP::Request.new(@session, :get, "/path", @options)
    request.update!(:headers => {'whatever' => 'value'}, :query => {'k1' => 'xx'}).should_not be_nil
    request.uri.to_s.should == 'https://api.grid5000.fr/path?k1=xx'
    request.head.should include("Whatever"=>"value", 'Accept' => 'text/plain')
  end
  
  it "should return nil if no changes were made when updating the request" do
    @options[:query] = {:k1 => 'v1', :k2 => [1,2,3]}
    request = Restfully::HTTP::Request.new(@session, :get, "/path", @options)
    request.update!(@options).should be_nil
  end
  
  it "should tell if the request is no-cache" do
    @options[:head]['Cache-Control'] = 'no-cache, max-age=0'
    request = Restfully::HTTP::Request.new(@session, :get, "/path", @options)
    request.no_cache?.should be_true
  end
  
  describe "with body" do
    it "should correctly build the request [body as hash, no content-type]" do
      @options[:body] = {"k1" => 'value1', 'k2' => ['a','b','c']}
      request = Restfully::HTTP::Request.new(@session, :post, "/path", @options)
      request.head['Content-Type'].
        should == 'application/x-www-form-urlencoded'
      request.method.should == :post
      request.body.should == "k1=value1&k2[]=a&k2[]=b&k2[]=c"
    end

    it "should correctly build the request [body as hash, content-type=json]" do
      @options[:body] = {"k1" => 'value1', 'k2' => ['a','b','c']}
      @options[:head][:content_type] = 'application/json'

      request = Restfully::HTTP::Request.new(@session, :post, "/path", @options)
      request.head['Content-Type'].
        should == 'application/json'
      request.method.should == :post
      request.body.should == JSON.dump(@options[:body])
    end
  
    it "should correctly build the request [body as string, content-type=json]" do
      @options[:body] = JSON.dump({"k1" => 'value1', 'k2' => ['a','b','c']})
      @options[:head][:content_type] = 'application/json'
      request = Restfully::HTTP::Request.new(@session, :post, "/path", @options)
      
      request.head['Content-Type'].
        should == 'application/json'
      request.body.should == @options[:body]
    end
    
    it "should correctly build the request [body as Hash, content-type=xml]" do
      Restfully::MediaType.register Restfully::MediaType::ApplicationVndBonfireXml
      @options[:body] = {"name" => "whatever"}
      @options[:head][:content_type] = 'application/vnd.bonfire+xml'
      @options[:serialization] = {"__type__" => "network"}
      request = Restfully::HTTP::Request.new(@session, :post, "/path", @options)
      request.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<network xmlns=\"http://api.bonfire-project.eu/doc/schemas/occi\">\n  <name>whatever</name>\n</network>\n"
    end
  end
  
  describe "execute" do
    before do
      @request = Restfully::HTTP::Request.new(
        @session,
        :get,
        "/path"
      )
    end
    it "should build the RestClient::Resource and build a response" do
      RestClient::Resource.should_receive(:new).with(
        @request.uri.to_s, 
        :headers => @request.head
      ).and_return(
        resource = mock(RestClient::Resource)
      )
      resource.should_receive(:get).and_return([
        200, 
        {'Content-Type' => 'text/plain'},
        ["hello"]
      ])
      response = @request.execute!
      response.should be_a(Restfully::HTTP::Response)
      response.code.should == 200
      response.body.should == "hello"
      response.head.should == {'Content-Type' => 'text/plain'}
    end
  end

end