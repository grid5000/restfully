require File.expand_path(File.dirname(__FILE__)+'/spec_helper')

include Restfully

describe Resource do
  before do
    @logger = Logger.new(STDOUT)
    @uri = URI.parse("http://api.local/x/y/z")
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
      resource.uri.should == URI.parse("uri")
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
      }
      @response_200 = Restfully::HTTP::Response.new(200, {'Content-Type' => 'application/json;utf-8', 'Content-Length' => @raw.length}, @raw.to_json)
    end
    it "should not be loaded in its initial state" do
      resource = Resource.new(@uri, mock('session'))
      resource.executed_requests.should == {}
    end
    it "should get the raw representation of the resource via the session if it doesn't have it" do
      resource = Resource.new(@uri, session = mock("session", :logger => Logger.new(STDOUT)))
      resource.stub!(:define_link) # do not define links
      session.should_receive(:get).with(@uri, {}).and_return(@response_200)
      resource.load
    end
    it "should get the raw representation of the resource via the session if there are query parameters" do
      resource = Resource.new(@uri, session = mock("session", :logger => Logger.new(STDOUT)))
      resource.stub!(:define_link) # do not define links
      session.should_receive(:get).with(@uri, {:query => {:q1 => 'v1'}}).and_return(@response_200)
      resource.load(:query => {:q1 => 'v1'})
    end
    it "should get the raw representation of the resource if forced to do so" do
      resource = Resource.new(@uri, session = mock("session", :logger => Logger.new(STDOUT)))
      resource.stub!(:define_link) # do not define links
      session.should_receive(:get).with(@uri, {}).and_return(@response_200)
      resource.load(:reload => true)
    end
    it "should correctly define the functions to access simple values" do
      resource = Resource.new(@uri, session = mock("session", :get => @response_200, :logger => @logger))
      resource.stub!(:define_link) # do not define links
      resource.load
      resource['whatever'].should == 'whatever'
      resource.uri.should == @uri
      resource["uid"].should == 'rennes'
      resource['an_array'].should be_a(SpecialArray)
      resource['an_array'].should == [1,2,3]
      lambda{resource.clusters}.should raise_error(NoMethodError)
    end
    
    it "should correctly define a collection link" do
      resource = Resource.new(@uri, session = mock("session", :get => mock("restfully response", :body => {
        'links' => [
          {'rel' => 'self', 'href' => '/grid5000/sites/rennes'},
          {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/versions', 'resolvable' => false, 'title' => 'versions'}
        ],
        'uid' => 'rennes'
      }, :headers => {}), :logger => @logger))
      Collection.should_receive(:new).with(@uri.merge('/grid5000/sites/rennes/versions'), session, :title => 'versions').and_return(collection=mock("restfully collection"))
      resource.load
      resource.links['versions'].should == collection
    end
    it "should NOT update the URI with the self link" do
      resource = Resource.new(@uri, session = mock("session", :get => mock("restfully response", :body => {
        'links' => [
          {'rel' => 'self', 'href' => '/grid5000/sites/rennes'}
        ],
        'uid' => 'rennes'
      }, :headers => {}), :logger => @logger))
      resource.uri.should == @uri
      resource.load
      resource.uri.should == @uri
    end
    it "should correctly define a member association" do
      resource = Resource.new(@uri, session = mock("session", :get => mock("restfully response", :body => {
        'links' => [
          {'rel' => 'member', 'href' => '/grid5000/sites/rennes/versions/123', 'title' => 'version'}
        ],
        'uid' => 'rennes'
      }, :headers => {}), :logger => @logger))
      Resource.should_receive(:new).with(@uri.merge('/grid5000/sites/rennes/versions/123'), session, :title => 'version').and_return(member=mock("restfully resource"))
      resource.load
      resource.links['version'].should == member
    end
    it "should correctly define a parent association" do
      resource = Resource.new(@uri, session = mock("session", :get => mock("restfully response", :body => {
        'links' => [
          {'rel' => 'self', 'href' => '/grid5000/sites/rennes'},
          {'rel' => 'parent', 'href' => '/grid5000'}
        ],
        'uid' => 'rennes'
      }, :headers => {}), :logger => @logger))
      Resource.should_receive(:new).with(@uri.merge('/grid5000'), session).and_return(parent=mock("restfully resource"))
      resource.load
      resource.links['parent'].should == parent
    end
    it "should ignore bad links" do
      resource = Resource.new(@uri, session = mock("session", :get => mock("restfully response", :body => {
        'links' => [
          {'rel' => 'self', 'href' => '/grid5000/sites/rennes'},
          {'rel' => 'invalid_rel', 'href' => '/whatever'},
          {'rel' => 'collection', 'href' => '/has/no/title'} 
        ],
        'uid' => 'rennes'
      }, :headers => {}), :logger => @logger))
      resource.load
      resource.links.should be_empty
    end
    
    it "should correctly define the functions to access links [integration test]" do
      resource = Resource.new(@uri, session = mock("session", :get => @response_200, :logger => @logger))
      @logger.should_receive(:warn).with(/collection \/has\/no\/title has no title/)
      @logger.should_receive(:warn).with(/invalid_rel is not a valid link relationship/)
      resource.load
      resource.links.keys.should =~ ['versions', 'clusters', 'environments', 'status', 'parent', 'version']
    end
  end
  
  
  describe "submitting" do
    before do
      @resource = Resource.new(@uri, @session = mock("session", :logger => @logger))
      @resource.stub!(:http_methods).and_return(['GET', 'POST'])
      @resource.stub!(:executed_requests).and_return({
        'GET' => {'headers' => {'Content-Type' => 'application/vnd.fr.grid5000.api.Job+json;level=1,application/json'}, 'options' => {:query => {:q1 => 'v1'}}}
      })
    end
    describe "setting input body and options" do
      before do
        @resource.stub!(:reload).and_return(@resource)
        @response = mock("http response", :status => 200)
      end
      it "should raise a NotImplementedError if the resource does not allow POST" do
        @resource.should_receive(:http_methods).and_return(['GET'])
        lambda{@resource.submit("whatever")}.should raise_error(NotImplementedError, /POST method is not allowed for this resource/)
      end
      it "should raise an error if the input body is nil" do
        lambda{@resource.submit(nil)}.should raise_error(ArgumentError, /You must pass a payload/)
      end
      it "should pass the body as-is if the given body is a string" do
        @session.should_receive(:post).with(@resource.uri, "whatever", :headers => {
          :accept => 'application/vnd.fr.grid5000.api.Job+json;level=1,application/json', 
          :content_type => 'application/json'}
          ).and_return(@response)
        @resource.submit("whatever")
      end
      it "should also pass the body as-is if the given body is an object" do
        body = {:key => 'value'}
        @session.should_receive(:post).with(@resource.uri, body, :headers => {
          :accept => 'application/vnd.fr.grid5000.api.Job+json;level=1,application/json', 
          :content_type => 'application/json'}).and_return(@response)
        @resource.submit(body)
      end
      it "should set the Content-Type header to the specified mime-type if given" do
        @session.should_receive(:post).with(@resource.uri, "whatever", :headers => {
          :accept => 'application/vnd.fr.grid5000.api.Job+json;level=1,application/json', 
          :content_type => 'application/xml'}).and_return(@response)
        @resource.submit("whatever", :headers => {:content_type => 'application/xml'})
      end
    end
    [201, 202].each do |status|
      it "should return the resource referenced in the Location header after a successful submit (status=#{status})" do
        @session.should_receive(:post).and_return(response = mock("http response", :status => status, :headers => {'Location' => '/path/to/new/resource'}))
        @resource.should_receive(:uri_for).with('/path/to/new/resource').and_return(new_resource_uri = mock("uri"))
        Resource.should_receive(:new).with(new_resource_uri, @session).and_return(new_resource = mock("resource"))
        new_resource.should_receive(:load).and_return(new_resource)
        @resource.submit("whatever").should == new_resource
      end
    end
    it "should reload the resource if the response status is 2xx (and not 201 or 202)" do
      @session.should_receive(:post).and_return(response = mock("http response", :status => 200, :headers => {'Location' => '/path/to/new/resource'}))
      @resource.should_receive(:reload).and_return(@resource)
      @resource.submit("whatever").should == @resource
    end
  end
end