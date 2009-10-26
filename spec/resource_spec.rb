require File.expand_path(File.dirname(__FILE__)+'/spec_helper')

include Restfully

describe Resource do
  before do
    @logger = Logger.new(STDOUT)
  end
  
  it "should have all the methods of a hash" do
    resource = Resource.new("uri", session=mock('session'))
    resource.size.should == 0
    resource['whatever'] = 'thing'
    resource.size.should == 1
    resource.should == {'whatever' => 'thing'}
    resource.should respond_to(:each)
    resource.should respond_to(:length)
  end
  
  describe "accessors" do
    it "should have a reader on the session" do
      resource = Resource.new("uri", session=mock("session"))
      resource.should_not respond_to(:session=)
      resource.session.should == session
    end
    it "should have a reader on the uri" do
      resource = Resource.new("uri", session=mock("session"))
      resource.should_not respond_to(:uri=)
      resource.uri.should == "uri"
    end
    it "should have a reader on the raw property" do
      resource = Resource.new("uri", session=mock("session"))
      resource.should_not respond_to(:raw=)
      resource.load('raw' => {:a => :b}).raw.should == {:a => :b}
    end
    it "should have a reader on the state property" do
      resource = Resource.new("uri", session=mock("session"))
      resource.should_not respond_to(:state=)
      resource.state.should == :unloaded
    end
  end
  
  
  describe "loading" do
  
    before do
      @raw = {
        'links' => [
          {'rel' => 'self', 'href' => '/grid5000/sites/rennes'},
          {'rel' => 'parent', 'href' => '/grid5000'},
          {'rel' => 'invalid_rel', 'href' => '/whatever'},
          {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/status', 'title' => 'status'},
          {'rel' => 'member', 'href' => '/grid5000/sites/rennes/versions/123', 'title' => 'version'},
          {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/versions', 'resolvable' => false, 'title' => 'versions'},
          {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/clusters', 'resolvable' => true, 'resolved' => true, 'title' => 'clusters'},
          {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/environments/versions/123', 'resolvable' => true, 'resolved' => false, 'title' => 'environments'},
          {'rel' => 'collection', 'href' => '/has/no/title'} 
        ],
        'uid' => 'rennes',
        'whatever' => 'whatever',
        'an_array' => [1, 2, 3],
        'clusters' => {
          'paradent' => {
            'uid' => 'paradent',
            'links' => [
              {'rel' => 'self', 'href' => '/grid5000/sites/rennes/clusters/paradent'},
              {'rel' => 'parent', 'href' => '/grid5000/sites/rennes'},
              {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/clusters/paradent/nodes', 'title' => 'nodes', 'resolvable' => true, 'resolved' => false},
              {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/clusters/paradent/versions', 'resolvable' => false, 'title' => 'versions'},
              {'rel' => 'member', 'href' => '/grid5000/sites/rennes/clusters/paradent/versions/123', 'title' => 'version'},
              {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/clusters/paradent/status', 'title' => 'status'}
            ],
            'model' => 'XYZ'
          },
          'paramount' => {
            'uid' => 'paramount',
            'links' => [
              {'rel' => 'self', 'href' => '/grid5000/sites/rennes/clusters/paramount'},
              {'rel' => 'parent', 'href' => '/grid5000/sites/rennes'},
              {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/clusters/paramount/nodes', 'title' => 'nodes', 'resolvable' => true, 'resolved' => false},
              {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/clusters/paramount/versions', 'resolvable' => false, 'title' => 'versions'},
              {'rel' => 'member', 'href' => '/grid5000/sites/rennes/clusters/paramount/versions/123', 'title' => 'version'},
              {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/clusters/paramount/status', 'title' => 'status'}
            ],
            'model' => 'XYZ1b'
          }
        }
      }.to_json
      @response_200 = Restfully::HTTP::Response.new(200, {'Content-Type' => 'application/json;utf-8', 'Content-Length' => @raw.length}, @raw)
    end
    it "should not be loaded in its initial state" do
      resource = Resource.new(mock("uri"), mock('session'))
      resource.should_not be_loaded
    end
    it "should get the raw representation of the resource via the session if it doesn't have it" do
      resource = Resource.new(uri=mock("uri"), session = mock("session", :logger => Logger.new(STDOUT)))
      resource.stub!(:define_link) # do not define links
      resource.raw.should be_nil
      session.should_receive(:get).with(uri, {}).and_return(@response_200)
      resource.load
      resource.should be_loaded
    end
    it "should get the raw representation of the resource via the session if there are query parameters" do
      resource = Resource.new(uri=mock("uri"), session = mock("session", :logger => Logger.new(STDOUT)))
      resource.stub!(:define_link) # do not define links
      resource.stub!(:loaded?).and_return(true) # should force reload even if already loaded
      resource.raw.should be_nil
      session.should_receive(:get).with(uri, {:query => {:q1 => 'v1'}}).and_return(@response_200)
      resource.load(:query => {:q1 => 'v1'})
    end
    it "should get the raw representation of the resource if forced to do so" do
      resource = Resource.new(uri=mock("uri"), session = mock("session", :logger => Logger.new(STDOUT)))
      resource.stub!(:define_link) # do not define links
      resource.stub!(:loaded?).and_return(true) # should force reload even if already loaded
      resource.raw.should be_nil
      session.should_receive(:get).with(uri, {}).and_return(@response_200)
      resource.load(:reload => true)
    end
    it "should correctly define the functions to access simple values" do
      resource = Resource.new("uri", session = mock("session", :get => @response_200, :logger => @logger))
      resource.stub!(:define_link) # do not define links
      resource.load
      resource['whatever'].should == 'whatever'
      resource.uri.should == 'uri'
      resource.uid.should == 'rennes'
      resource['an_array'].should be_a(SpecialArray)
      resource['an_array'].should == [1,2,3]
      lambda{resource.clusters}.should raise_error(NoMethodError)
    end
    
    it "should correctly define a collection association" do
      resource = Resource.new("uri", session = mock("session", :get => mock("restfully response", :body => {
        'links' => [
          {'rel' => 'self', 'href' => '/grid5000/sites/rennes'},
          {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/versions', 'resolvable' => false, 'title' => 'versions'}
        ],
        'uid' => 'rennes'
      }), :logger => @logger))
      Collection.should_receive(:new).with('/grid5000/sites/rennes/versions', session, :title => 'versions', :raw => nil).and_return(collection=mock("restfully collection"))
      resource.load
      resource.associations['versions'].should == collection
    end
    it "should NOT update the URI with the self link" do
      resource = Resource.new("uri", session = mock("session", :get => mock("restfully response", :body => {
        'links' => [
          {'rel' => 'self', 'href' => '/grid5000/sites/rennes'}
        ],
        'uid' => 'rennes'
      }), :logger => @logger))
      resource.uri.should == "uri"
      resource.load
      resource.uri.should == "uri"
    end
    it "should correctly define a member association" do
      resource = Resource.new("uri", session = mock("session", :get => mock("restfully response", :body => {
        'links' => [
          {'rel' => 'member', 'href' => '/grid5000/sites/rennes/versions/123', 'title' => 'version'}
        ],
        'uid' => 'rennes'
      }), :logger => @logger))
      Resource.should_receive(:new).with('/grid5000/sites/rennes/versions/123', session, :title => 'version', :raw => nil).and_return(member=mock("restfully resource"))
      resource.load
      resource.associations['version'].should == member
    end
    it "should correctly define a parent association" do
      resource = Resource.new("uri", session = mock("session", :get => mock("restfully response", :body => {
        'links' => [
          {'rel' => 'self', 'href' => '/grid5000/sites/rennes'},
          {'rel' => 'parent', 'href' => '/grid5000'}
        ],
        'uid' => 'rennes'
      }), :logger => @logger))
      Resource.should_receive(:new).with('/grid5000', session).and_return(parent=mock("restfully resource"))
      resource.load
      resource.associations['parent'].should == parent
    end
    it "should ignore bad links" do
      resource = Resource.new("uri", session = mock("session", :get => mock("restfully response", :body => {
        'links' => [
          {'rel' => 'self', 'href' => '/grid5000/sites/rennes'},
          {'rel' => 'invalid_rel', 'href' => '/whatever'},
          {'rel' => 'collection', 'href' => '/has/no/title'} 
        ],
        'uid' => 'rennes'
      }), :logger => @logger))
      resource.load
      resource.associations.should be_empty
    end
    
    it "should correctly define the functions to access links [integration test]" do
      resource = Resource.new("uri", session = mock("session", :get => @response_200, :logger => @logger))
      @logger.should_receive(:warn).with(/collection \/has\/no\/title has no title/)
      @logger.should_receive(:warn).with(/invalid_rel is not a valid link relationship/)
      resource.load
      resource.associations.keys.should =~ ['versions', 'clusters', 'environments', 'status', 'parent', 'version']
    end
  end
end