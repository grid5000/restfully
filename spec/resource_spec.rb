require File.dirname(__FILE__)+'/spec_helper'

include Restfully

describe Resource do
  before do
    @logger = Logger.new(STDOUT)
  end
  
  it "should have all methods of a hash" do
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
    it "should have an accessor on parent" do
      parent = mock("parent")
      resource = Resource.new("uri", session=mock("session"), 'parent' => parent)
      parent.should_receive(:load).and_return(parent)
      resource.parent.should == parent
      new_parent = mock("new parent")
      new_parent.should_receive(:load).and_return(new_parent)
      resource.parent = new_parent
      resource.parent.should == new_parent
    end
    it "should have a reader on the raw property" do
      resource = Resource.new("uri", session=mock("session"), 'raw' => {})
      resource.should_not respond_to(:raw=)
      resource.raw.should == {}
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
          {'rel' => 'self', 'href' => '/sites/rennes/versions/123'},
          {'rel' => 'parent', 'href' => '/versions/123'},
          {'rel' => 'invalid_rel', 'href' => '/whatever'},
          {'rel' => 'member', 'href' => '/sites/rennes/statuses/current', 'title' => 'status'},
          {'rel' => 'collection', 'href' => '/sites/rennes/versions', 'resolvable' => false, 'title' => 'versions'},
          {'rel' => 'collection', 'href' => '/sites/rennes/clusters/versions/123', 'resolvable' => true, 'resolved' => true, 'title' => 'clusters'},
          {'rel' => 'collection', 'href' => '/sites/rennes/environments/versions/123', 'resolvable' => true, 'resolved' => false, 'title' => 'environments'},
          {'rel' => 'collection', 'href' => '/has/no/title'} 
        ],
        'guid' => '/sites/rennes',
        'whatever' => 'whatever',
        'an_array' => [1, 2, 3],
        'clusters' => {
          '/sites/rennes/clusters/paradent' => {
            'guid' => '/sites/rennes/clusters/paradent',
            'links' => [
              {'rel' => 'self', 'href' => '/sites/rennes/clusters/paradent/versions/123'},
              {'rel' => 'parent', 'href' => '/sites/rennes/versions/123'},
              {'rel' => 'collection', 'href' => '/sites/rennes/clusters/paradent/nodes/versions/123', 'title' => 'nodes', 'resolvable' => true, 'resolved' => false},
              {'rel' => 'collection', 'href' => '/sites/rennes/clusters/paradent/versions', 'resolvable' => false, 'title' => 'versions'},
              {'rel' => 'member', 'href' => '/sites/rennes/clusters/paradent/statuses/current', 'title' => 'status'}
            ],
            'model' => 'XYZ'
          },
          '/sites/rennes/clusters/paramount' => {
            'guid' => '/sites/rennes/clusters/paramount',
            'links' => [
              {'rel' => 'self', 'href' => '/sites/rennes/clusters/paramount/versions/123'},
              {'rel' => 'parent', 'href' => '/sites/rennes/versions/123'},
              {'rel' => 'collection', 'href' => '/sites/rennes/clusters/paramount/nodes/versions/123', 'title' => 'nodes', 'resolvable' => true, 'resolved' => false},
              {'rel' => 'collection', 'href' => '/sites/rennes/clusters/paramount/versions', 'resolvable' => false, 'title' => 'versions'},
              {'rel' => 'member', 'href' => '/sites/rennes/clusters/paramount/statuses/current', 'title' => 'status'}
            ],
            'model' => 'XYZ1b'
          }
        }
      }
    end
    it "should not be loaded in its initial state" do
      resource = Resource.new("uri", mock('session'))
      resource.should_not be_loaded
    end
    it "should get the raw representation of the resource via the session if it doesn't have it" do
      resource = Resource.new("uri", session = mock("session", :logger => Logger.new(STDOUT)))
      resource.stub!(:define_link) # do not define links
      resource.raw.should be_nil
      session.should_receive(:get).with('uri').and_return(@raw)
      resource.load
    end
    it "should correctly define the functions to access simple values" do
      resource = Resource.new("uri", session = mock("session", :get => @raw, :logger => @logger))
      resource.stub!(:define_link) # do not define links
      resource.load
      resource['whatever'].should == 'whatever'
      resource.uri.should == 'uri'
      resource.guid.should == '/sites/rennes'
      resource['an_array'].should be_a(SpecialArray)
      resource['an_array'].should == [1,2,3]
      lambda{resource.clusters}.should raise_error(NoMethodError)
    end
    
    it "should correctly define the functions to access links" do
      resource = Resource.new("uri", session = mock("session", :get => @raw, :logger => @logger))
      @logger.should_receive(:warn).with(/collection \/has\/no\/title has no title/)
      @logger.should_receive(:warn).with(/invalid_rel is not a valid link relationship/)
      Collection.should_receive(:new).
        with('/sites/rennes/versions', session, 'raw' => nil, 'parent' => resource, 'title' => 'versions').
        and_return(versions=mock(Collection))
      Collection.should_receive(:new).
        with('/sites/rennes/clusters/versions/123', session, 'raw' => @raw['clusters'], 'parent' => resource, 'title' => 'clusters').
        and_return(clusters=mock(Collection))
      Collection.should_receive(:new).
        with('/sites/rennes/environments/versions/123', session, 'raw' => nil, 'parent' => resource, 'title' => 'environments').
        and_return(environments=mock(Collection))
      Resource.should_receive(:new).
        with('/versions/123', session).
        and_return(parent=mock(Resource))
      Resource.should_receive(:new).
        with('/sites/rennes/statuses/current', session, 'raw' => nil, 'parent' => resource).
        and_return(status=mock(Resource))
      # associations should not exist before loading
      resource.respond_to?(:clusters).should be_false
      # load the resource so that associations get created
      resource.load
      # check that functions exist
      resource.should respond_to(:clusters)
      clusters.should_receive(:load).and_return(clusters)
      resource.clusters.should == clusters
      resource.should respond_to(:environments)
      environments.should_receive(:load).and_return(environments)
      resource.environments.should == environments
      resource.should respond_to(:versions)
      versions.should_receive(:load).and_return(versions)
      resource.versions.should == versions
      resource.should respond_to(:status)
      status.should_receive(:load).and_return(status)
      resource.status.should == status
      parent.should_receive(:load).and_return(parent)
      resource.parent.should == parent
      resource.uri.should == 'uri' # self link should not override it
    end
  end
end