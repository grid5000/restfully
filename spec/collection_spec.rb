require File.expand_path(File.dirname(__FILE__)+'/spec_helper')

include Restfully
describe Collection do
  describe "general behaviour" do
    before do
      @collection = Collection.new("uri", session=mock('session')).load(:raw => JSON.parse(fixture("grid5000-sites.json")))
    end
    it "should be enumerable" do
      @collection.length.should == 9
      @collection.map{|site| site.uid}.sort.should == ["bordeaux", "grenoble", "lille", "lyon", "nancy", "orsay", "rennes", "sophia", "toulouse"]
    end
  
    it "should have a :total method" do
      @collection.total.should == 9
    end
  
    it "should have a :offset method" do
      @collection.offset.should == 0
    end
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
      collection.instance_variable_set(:@last_request_hash, [:get, {}].hash)
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
        "total" => 1,
        "offset" => 0,
        "items" => [
          {
            'links' => [
              {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/versions', 'resolvable' => false, 'title' => 'versions'}
            ],
            'uid' => 'rennes'
          }
        ]
      }), :logger => @logger))
      Resource.should_not_receive(:new)
      collection.load
      collection.by_uid('rennes').should be_nil
    end
    it "should initialize resources having a self link" do
      collection = Collection.new("uri", session = mock("session", :get => mock("restfully response", :body => {
        "total" => 1,
        "offset" => 0,
        "items" => [
          {
            'links' => [
              {'rel' => 'self', 'href' => '/grid5000/sites/rennes'},
              {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/versions', 'title' => 'versions'}
            ],
            'uid' => 'rennes'
          }
        ]
      }), :logger => @logger))
      collection.load
      collection.length.should == 1
      collection.by_uid('rennes').class.should == Restfully::Resource
    end
    it "should correctly initialize its resources [integration test]" do
      collection = Collection.new("uri", session=mock("session", :logger => Logger.new(STDOUT), :get => @response_200))
      collection.load
      collection.should be_loaded
      collection.uri.should == "uri"
      collection.by_uid('rennes').uid.should == 'rennes'
      collection.by_uid('rennes').type.should == 'site'
      collection.by_uid.keys.should =~ ['rennes', 'lille', 'bordeaux', 'nancy', 'sophia', 'toulouse', 'lyon', 'grenoble', 'orsay']
      collection.by_uid('rennes', 'bordeaux').length.should == 2
    end 
  end
  
end