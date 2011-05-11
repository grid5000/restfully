require 'spec_helper'

describe Restfully::Collection do
  before do
    Restfully::MediaType.register Restfully::MediaType::ApplicationVndBonfireXml
    
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
  
  it "should expand the items" do
    @response = Restfully::HTTP::Response.new(
      @session, 200, {
        'Content-Type' => 'application/vnd.bonfire+xml; charset=utf-8'
      }, fixture('bonfire-collection-with-fragments.xml')
    )
    @resource = Restfully::Resource.new(@session, @response, @request).load
    @resource.all?{|i| i.complete?}.should be_false
    stub_request(:get, "https://api.grid5000.fr/locations/de-hlrs/networks/29").
      with(:headers => {'Accept'=>'application/vnd.bonfire+xml', 'Accept-Encoding'=>'gzip, deflate', 'Cache-Control'=>'no-cache'}).
      to_return(:status => 200, :body => fixture("bonfire-network-existing.xml"), :headers => {'Content-Type' => 'application/vnd.bonfire+xml'})
    @resource.expand
    @resource.all?{|i| i.complete?}.should be_true
  end
  
  it "should be empty if no item" do
    @response = Restfully::HTTP::Response.new(
      @session, 200, {
        'Content-Type' => 'application/vnd.bonfire+xml; charset=utf-8'
      }, fixture('bonfire-empty-collection.xml')
    )
    @resource = Restfully::Resource.new(@session, @response, @request).load
    @resource.collection?.should be_true
    @resource.should be_empty
    @resource.total.should == 0
    @resource.length.should == 0
    @resource.offset.should == 0
    @resource.map{|i| i}.should == []
  end
  
  describe "finders" do
    before do
      @response = Restfully::HTTP::Response.new(
        @session, 200, {
          'Content-Type' => 'application/vnd.bonfire+xml; charset=utf-8'
        }, fixture('bonfire-experiment-collection.xml')
      )
      @resource = Restfully::Resource.new(@session, @response, @request).load
    end
    it "should find an item by uid" do
      @resource[:'3'].should_not be_nil
    end
    it "should find an item by index" do
      @resource[0].should == @resource.first
    end
    it "should reload the item if not complete" do
      @resource.map{|i| 
        if i["id"] == "3"
          i.media_type.should_receive(:complete?).and_return(false)
          i.should_receive(:reload).once 
        end
      }
      @resource[:'3'].should_not be_nil
    end
  end

  
end
