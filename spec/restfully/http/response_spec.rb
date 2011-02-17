require 'spec_helper'

describe Restfully::HTTP::Response do
  before do
    @session = mock(Restfully::Session)
    @io = StringIO.new(fixture('grid5000-rennes.json'))
  end
  it "should correctly initialize the response" do
    content = @io.read
    @io.rewind
    response = Restfully::HTTP::Response.new(@session, 200, {
      'Content-Type' => 'application/json'
    }, @io)

    response.code.should == 200
    response.head.should == {"Content-Type"=>"application/json"}
    response.media_type.should be_a(Restfully::MediaType::ApplicationJson)
    response.io.should be_a(StringIO)
    response.body.should == content
    response.io.read.should == content
  end
  
  
  it "should always allow :get" do
    response = Restfully::HTTP::Response.new(@session, 200, {
      'Content-Type' => 'application/json'
    }, @io)
    response.allow?(:get).should be_true
  end
  
  it "should find the allowed methods in the header (if any)" do
    response = Restfully::HTTP::Response.new(@session, 200, {
      'Content-Type' => 'application/json',
      'Allow' => 'GET, POST'
    }, @io)
    
    response.allow?(:get).should be_true
    response.allow?(:post).should be_true
  end
  
  it "should raise an error if it cannot find a corresponding media-type" do
    response = Restfully::HTTP::Response.new(@session, 200, {
      'Content-Type' => 'whatever'
    }, @io)
    lambda{
      response.media_type
    }.should raise_error(
      Restfully::Error, 
      "Cannot find a media-type for content-type=\"whatever\""
    )
    
  end
end