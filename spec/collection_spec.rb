require File.expand_path(File.dirname(__FILE__)+'/spec_helper')

include Restfully
describe Collection do
  describe "general behaviour" do
    before do
      @uri = URI.parse('http://api.local/x/y/z')
      @collection = Collection.new(@uri, session=mock('session')).load(:body => JSON.parse(fixture("grid5000-sites.json")))
      @jobs_collection = Collection.new(@uri, session=mock('session')).load(:body => JSON.parse(fixture("grid5000-rennes-jobs.json")))
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
    
    it "should try to find the matching item in the collection when calling [] with a symbol" do
      rennes = @collection[:rennes]
      rennes.class.should == Restfully::Resource
      rennes['uid'].should == 'rennes'
    end
    it "should try to find the matching item in the collection when calling [] with a symbol" do
      job = @jobs_collection[:'319482']
      job.class.should == Restfully::Resource
      job['uid'].should == 319482
    end
    it "should make a direct request to collection_uri/resource_uid when calling [] and the searched item is not in the collection" do
      Restfully::Resource.should_receive(:new).with('http://api.local/x/y/z/not_in_the_collection', @collection.session).and_return(resource = mock("resource"))
      resource.should_receive(:load).and_return(resource)
      @collection[:not_in_the_collection].should == resource
    end
    it "should go through the 'next' links (if any) to search for the requested item" do
      body = JSON.parse(fixture("grid5000-rennes-jobs.json"))
      body["total"] = 20
      body1 = JSON.parse(fixture("grid5000-rennes-jobs.json"))
      body["total"] = 20
      body1["offset"] = 8
      body2 = JSON.parse(fixture("grid5000-rennes-jobs.json"))
      body["total"] = 20
      body2["offset"] = 16
      body2["items"][1]["uid"] = "18th item"
      collection = Collection.new(@uri, session = mock('session')).load(:body => body)
      session.should_receive(:get).with(@uri, :query => {:offset => 8}).ordered.and_return(response = mock("response", :body => body1, :status => 200, :headers => {}))
      session.should_receive(:get).with(@uri, :query => {:offset => 16}).ordered.and_return(response = mock("response", :body => body2, :status => 200, :headers => {}))
      collection.find{|item| item["uid"] == "18th item"}.should_not be_nil
    end
    it "should always return nil if the searched item is not in the collection" do
      Restfully::Resource.should_receive(:new).with('http://api.local/x/y/z/doesnotexist', @collection.session).and_return(resource = mock("resource"))
      resource.should_receive(:load).and_raise Restfully::HTTP::ClientError.new(mock("response", :body => "Not Found", :status => 404))
      @collection[:doesnotexist].should be_nil
    end
  end  
  
  describe "populating collection" do
    before do
      @uri = "http://server.com/path/to/collection"
      @session = mock("session", :logger => Logger.new($stderr))
      @collection = Collection.new(@uri, @session)
    end
    it "should define links" do
      Link.should_receive(:new).with({"rel" => "self", "href" => "/path/to/collection"}).and_return(link1=mock("link1"))
      Link.should_receive(:new).with({"rel" => "member", "href" => "/path/to/member", "title" => "member_title"}).and_return(link2=mock("link2"))
      @collection.should_receive(:define_link).with(link1)
      @collection.should_receive(:define_link).with(link2)
      @collection.populate_object("links", [
        {"rel" => "self", "href" => "/path/to/collection"},
        {"rel" => "member", "href" => "/path/to/member", "title" => "member_title"}
      ])
    end
    it "should create a new resource for each item" do
      items = [
        {
          'links' => [
            {'rel' => 'self', 'href' => '/grid5000/sites/rennes'},
            {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/versions', 'title' => 'versions'}
          ],
          'uid' => 'rennes'
        }
      ]
      @collection.populate_object("items", items)
      @collection.find{|i| i['uid'] == 'rennes'}.class.should == Restfully::Resource
    end

    it "should not initialize resources lacking a self link" do
      items = [
        {
          'links' => [
            {'rel' => 'collection', 'href' => '/grid5000/sites/rennes/versions', 'resolvable' => false, 'title' => 'versions'}
          ],
          'uid' => 'rennes'
        }
      ]
      @collection.populate_object("items", items)
      @collection.items.should be_empty
    end
    it "should store its properties in the internal hash" do
      @collection.populate_object("uid", "rennes")
      @collection.populate_object("list_of_values", [1,2,"whatever", {:x => :y}])
      @collection.populate_object("hash", {"a" => [1,2], "b" => "c"})
      @collection.properties.should == {
        "hash"=>{"a"=>[1, 2], "b"=>"c"}, 
        "list_of_values"=>[1, 2, "whatever", {:x=>:y}], 
        "uid"=>"rennes"
      }
      @collection["uid"].should == "rennes"
      @collection["hash"].should == {"a"=>[1, 2], "b"=>"c"}
      @collection["list_of_values"].should == [1, 2, "whatever", {:x=>:y}]
    end
  end

  
end