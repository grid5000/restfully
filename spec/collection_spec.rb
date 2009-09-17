require File.dirname(__FILE__)+'/spec_helper'

include Restfully
describe Collection do

  it "should have all methods of a hash" do
    collection = Collection.new("uri", session=mock('session'))
    collection.size.should == 0
    collection.store("rennes", resource = mock(Resource))
    collection.size.should == 1
    collection.should == {'rennes' => resource}
    collection.should respond_to(:each)
    collection.should respond_to(:store)
    collection.should respond_to(:[])
    collection.should respond_to(:length)
  end
  
  
  
  describe "loading" do
    before(:all) do
      @raw = fixture("grid5000-sites.json")
      @response_200 = Restfully::HTTP::Response.new(200, {'Content-Type' => 'application/json;charset=utf-8', 'Content-Length' => @raw.length}, @raw)
      @logger = Logger.new(STDOUT)
    end
    it "should not load if already loaded and no :reload" do
      collection = Collection.new("uri", mock("session"))
      collection.should_receive(:loaded?).and_return(true)
      collection.load(:reload => false).should == collection
    end
    it "should load when :reload param is true [already loaded]" do
      collection = Collection.new("uri", session=mock("session", :logger => Logger.new(STDOUT)))
      collection.should_receive(:loaded?).and_return(true)
      session.should_receive(:get).and_return(@response_200)
      collection.load(:reload => true).should == collection    
    end
    it "should load when force_reload is true [not loaded]" do
      collection = Collection.new("uri", session=mock("session", :logger => Logger.new(STDOUT)))
      collection.should_receive(:loaded?).and_return(false)
      session.should_receive(:get).and_return(@response_200)
      collection.load(:reload => true).should == collection    
    end
    it "should force reload when query parameters are given" do
      collection = Collection.new("uri", session=mock("session", :logger => Logger.new(STDOUT)))
      session.should_receive(:get).and_return(@response_200)
      collection.load(:query => {:q1 => 'v1'}).should == collection
    end
    it "should not initialize resources lacking a self link" do
      collection = Collection.new("uri", session = mock("session", :get => mock("restfully response", :body => {
        'rennes' => {
          'links' => [
            {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/versions', 'resolvable' => false, 'title' => 'versions'}
          ],
          'uid' => 'rennes'
        }
      }), :logger => @logger))
      Resource.should_not_receive(:new)
      collection.load
      collection['rennes'].should be_nil
    end
    it "should initialize resources having a self link" do
      collection = Collection.new("uri", session = mock("session", :get => mock("restfully response", :body => {
        'rennes' => {
          'links' => [
            {'rel' => 'self', 'href' => '/grid5000/sites/rennes'},
            {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/versions', 'resolvable' => false, 'title' => 'versions'}
          ],
          'uid' => 'rennes'
        }
      }), :logger => @logger))
      Resource.should_receive(:new).with('/grid5000/sites/rennes', session, :raw => {
        'links' => [
          {'rel' => 'self', 'href' => '/grid5000/sites/rennes'},
          {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/versions', 'resolvable' => false, 'title' => 'versions'}
        ],
        'uid' => 'rennes'
      }).and_return(resource=mock("restfully resource"))
      resource.should_receive(:load).and_return(resource)
      collection.load
      collection['rennes'].should == resource
    end
    it "should correctly initialize its resources [integration test]" do
      collection = Collection.new("uri", session=mock("session", :logger => Logger.new(STDOUT), :get => @response_200))
      collection.load
      collection.should be_loaded
      collection.uri.should == "uri"
      collection['rennes'].uid.should == 'rennes'
      collection['rennes'].type.should == 'site'
      collection.keys.should =~ ['rennes', 'lille', 'bordeaux', 'nancy', 'sophia', 'toulouse', 'lyon', 'grenoble', 'orsay']
    end 
  end
  
end