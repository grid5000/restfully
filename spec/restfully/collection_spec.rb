require 'spec_helper'

describe Restfully::Collection do
  before do
    @session = Restfully::Session.new(
      :uri => "https://api.grid5000.fr"
    )
    @request = Restfully::HTTP::Request.new(
      @session, :get, "/grid5000/sites/rennes/jobs",
      :head => {'Accept' => 'application/vnd.grid5000+json'}
    )
    @response = Restfully::HTTP::Response.new(
      @session, 200, {
        'Content-Type' => 'application/vnd.grid5000+json; charset=utf-8',
        'Allow' => 'GET,POST'
      }, fixture('grid5000-rennes-jobs.json')
    )
    Restfully::MediaType.register Restfully::MediaType::Grid5000
    @resource = Restfully::Resource.new(@session, @response, @request)
  end
  
  it "should include the Collection module if the resource is a collection" do
    @resource.should_receive(:extend).with(Restfully::Collection)
    @resource.load
  end
  
  it "should return the total number of elements" do
    @resource.load.total.should == 366486
  end
  
  it "should return the offset" do
    @resource.load.offset.should == 0
  end
  
  it "should iterate over the collection" do
    items = []
    @resource.load.each{|i| items << i}
    items.all?{|i| i.kind_of?(Restfully::Resource)}.should be_true
    items[0].relationships.map(&:to_s).sort.should == ["parent", "self"]
    items[0]['uid'].should == 376505
  end
end
