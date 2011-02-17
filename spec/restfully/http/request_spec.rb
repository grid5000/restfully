require 'spec_helper'

describe Restfully::HTTP::Request do
  before do
    @session = mock(
      Restfully::Session, 
      :default_headers => {
        'Accept' => '*/*; application/xml',
        :accept_encoding => "gzip, deflate"
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
    
  end
  
  it "should correctly build the request [no body]" do
    @session.should_receive(:uri_to).with("/path").
      and_return(URI.parse("https://api.grid5000.fr/path"))
    
    request = Restfully::HTTP::Request.new(@session, :get, "/path", @options)
    request.head.should == {
      'Cache-Control' => 'no-cache',
      'Some-Header' => 'some value',
      'Accept' => 'application/json',
      'Accept-Encoding' => 'gzip, deflate'
    }
    request.method.should == :get
  end
  
  describe "with body" do
    before do
      @session.should_receive(:uri_to).with("/path").
        and_return(URI.parse("https://api.grid5000.fr/path"))
      
    end
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
  end

end