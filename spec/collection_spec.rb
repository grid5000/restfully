require File.expand_path(File.dirname(__FILE__)+'/spec_helper')

include Restfully
describe Collection do
  describe "general behaviour" do
    before do
      @uri = URI.parse('http://api.local/x/y/z')
      @collection = Collection.new(@uri, session=mock('session')).load(:body => JSON.parse(fixture("grid5000-sites.json")))
    end
    it "should be enumerable" do
      @collection.length.should == 9
      @collection.size.should == 9
      @collection.map{|site| site["uid"]}.sort.should == ["bordeaux", "grenoble", "lille", "lyon", "nancy", "orsay", "rennes", "sophia", "toulouse"]
    end
  
    it "should have a :total attribute" do
      @collection["total"].should == 9
    end
  
    it "should have a :offset attribute" do
      @collection["offset"].should == 0
    end
  end  
  
  describe "loading" do
    before(:all) do
      @uri = URI.parse('http://api.local/x/y/z')
      @raw = fixture("grid5000-sites.json")
      @response_200 = Restfully::HTTP::Response.new(200, {'Content-Type' => 'application/json;charset=utf-8', 'Content-Length' => @raw.length}, @raw)
      @logger = Logger.new(STDOUT)
    end
    it "should not load if already loaded and no :reload" do
      collection = Collection.new(@uri, mock("session"))
      options = {:headers => {'key' => 'value'}}
      collection.should_receive(:executed_requests).and_return({'GET' => {'options' => options, 'body' => {"key" => "value"}}})
      collection.load(options.merge(:reload => false)).should == collection
    end
    it "should load when :reload param is true [already loaded]" do
      collection = Collection.new(@uri, session=mock("session", :logger => Logger.new(STDOUT)))
      session.should_receive(:get).and_return(@response_200)
      collection.load(:reload => true).should == collection    
    end
    it "should load when force_reload is true [not loaded]" do
      collection = Collection.new(@uri, session=mock("session", :logger => Logger.new(STDOUT)))
      session.should_receive(:get).and_return(@response_200)
      collection.load(:reload => true).should == collection    
    end
    it "should force reload when query parameters are given" do
      collection = Collection.new(@uri, session=mock("session", :logger => Logger.new(STDOUT)))
      session.should_receive(:get).and_return(@response_200)
      collection.load(:query => {:q1 => 'v1'}).should == collection
    end
    it "should not initialize resources lacking a self link" do
      collection = Collection.new(@uri, session = mock("session", :get => mock("restfully response", :body => {
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
      collection.find{|i| i['uid'] == 'rennes'}.should be_nil
    end
    it "should initialize resources having a self link" do
      collection = Collection.new(@uri, session = mock("session", :get => mock("restfully response", :body => {
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
      collection.find{|i| i['uid'] == 'rennes'}.class.should == Restfully::Resource
    end
    it "should correctly initialize its resources [integration test]" do
      collection = Collection.new(@uri, session=mock("session", :logger => Logger.new(STDOUT), :get => @response_200))
      collection.load
      collection.uri.should == @uri
      collection.find{|i| i['uid'] == 'rennes'}["uid"].should == 'rennes'
      collection.find{|i| i['uid'] == 'rennes'}["type"].should == 'site'
      collection.map{|s| s['uid']}.should =~ ['rennes', 'lille', 'bordeaux', 'nancy', 'sophia', 'toulouse', 'lyon', 'grenoble', 'orsay']
    end 
  end
  
end