require 'spec_helper'

describe Restfully::MediaType::ApplicationVndBonfireXml do
  before do
    Restfully::MediaType.register Restfully::MediaType::ApplicationVndBonfireXml

    @expected_compute_hash = {"name"=>"Compute name", "startup"=>{"href"=>"file:///path/to/startup-script/sh"}, "instance_type"=>"small", "__type__"=>"compute", "description"=>"Compute description", "nic"=>[{"device"=>"eth0", "mac"=>"AA:AA:AA:AA", "network"=>{"href"=>"/locations/fr-inria/networks/1"}, "ip"=>"123.123.123.123"}, {"device"=>"eth1", "mac"=>"BB:BB:BB:BB", "network"=>{"href"=>"/locations/fr-inria/networks/2"}, "ip"=>"123.123.124.2"}], "context"=>{"bonfire_credentials"=>"crohr:p4ssw0rd", "monitoring_ip"=>"123.123.123.2"}, "link"=>[{"href"=>"/locations/fr-inria", "rel"=>"location", "type"=>"application/vnd.bonfire+xml"}, {"href"=>"/locations/uk-epcc/computes/1", "rel"=>"self"}], "disk"=>[{"type"=>"OS", "storage"=>{"href"=>"/locations/fr-inria/storages/1"}, "target"=>"sda"}, {"type"=>"CDROM", "storage"=>{"href"=>"/locations/fr-inria/storages/2"}, "target"=>"sdc"}], "state"=>"ACTIVE"}
    @fixture = fixture("bonfire-compute-existing.xml")
    @collection = fixture("bonfire-network-collection.xml")
    @session = Restfully::Session.new(:uri => "http://localhost:8000")
  end

  describe "loading from xml" do
    it "should load the io into a Hash" do
      media = Restfully::MediaType::ApplicationVndBonfireXml.new(@fixture, @session)
      media.io.should == @fixture
      media.unserialized.should be_a(Hash)
    end

    it "should build the Hash from the XML doc [resource]" do
      media = Restfully::MediaType::ApplicationVndBonfireXml.new(@fixture, @session)
      media.property.should == @expected_compute_hash
    end

    it "should build the Hash from the XML doc [resource] 2" do
      media = Restfully::MediaType::ApplicationVndBonfireXml.new(
        fixture("bonfire-network-existing.xml"), @session
      )
      media.property.should == {"name"=>"Private LAN", "public"=>"YES", "id"=>"29", "__type__"=>"network", "link"=>[{"href"=>"/locations/de-hlrs/networks/29", "rel"=>"self"}]}
    end

    it "should build the Hash from the XML doc [resource] 3" do
      media = Restfully::MediaType::ApplicationVndBonfireXml.new(
        fixture("bonfire-experiment.xml"), @session
      )
      media.property.should == {"name"=>"expe1", "walltime"=>"2011-04-28T16:16:34Z", "id"=>"12", "__type__"=>"experiment", "user_id"=>"crohr", "storages"=>[{"name"=>"data", "href"=>"/locations/uk-epcc/storages/44"}], "description"=>"description expe1", "computes"=>[{"name"=>"compute expe1", "href"=>"/locations/fr-inria/computes/76"}, {"name"=>"compute2 expe1", "href"=>"/locations/uk-epcc/computes/47"}, {"name"=>"compute2 expe1", "href"=>"/locations/uk-epcc/computes/48"}], "link"=>[{"href"=>"/", "rel"=>"parent"}, {"href"=>"/experiments/12/storages", "rel"=>"storages"}, {"href"=>"/experiments/12/networks", "rel"=>"networks"}, {"href"=>"/experiments/12/computes", "rel"=>"computes"}, {"href"=>"/experiments/12", "rel"=>"self"}], "status"=>"running"}
    end

    it "should build the Hash from the XML doc [collection]" do
      media = Restfully::MediaType::ApplicationVndBonfireXml.new(@collection, @session)
      media.should be_collection
      media.property.should == {"items"=>[{"address"=>"10.0.0.1", "name"=>"Network1", "size"=>"C", "__type__"=>"network", "description"=>"Network1 description", "link"=>[{"href"=>"/locations/fr-inria", "rel"=>"location"}, {"href"=>"/locations/fr-inria/networks/1", "rel"=>"self"}], "visibility"=>"public"}, {"address"=>"10.0.0.1", "name"=>"Network2", "size"=>"C", "__type__"=>"network", "description"=>"Network2 description", "link"=>[{"href"=>"/locations/fr-inria", "rel"=>"location"}, {"href"=>"/locations/fr-inria/networks/2", "rel"=>"self"}], "visibility"=>"private"}], "total"=>2, "offset"=>0, "__type__"=>"network_collection", "link"=>[{"href"=>"/locations/fr-inria/networks?limit=20", "rel"=>"top", "type"=>"application/vnd.bonfire+xml"}, {"href"=>"/locations/fr-inria", "rel"=>"parent", "type"=>"application/vnd.bonfire+xml"}, {"href"=>"/locations/fr-inria/networks", "rel"=>"self"}]}
    end

    it "should build the Hash from the XML doc [empty collection]" do
      media = Restfully::MediaType::ApplicationVndBonfireXml.new(
        fixture("bonfire-empty-collection.xml"), @session
      )
      media.should be_collection
      items = []
      media.each{|i| items << i}
      items.should be_empty
    end

    it "should be able to iterate over a collection" do
      media = Restfully::MediaType::ApplicationVndBonfireXml.new(fixture("bonfire-experiment-collection.xml"), @session)
      items = []
      media.each{|i| items<<i}
      items.length.should == 3
    end


  end

  describe "restfully resource" do
    it "should correctly load a resource" do
      req = Restfully::HTTP::Request.new(@session, :get, "http://localhost:8000/locations/de-hlrs/networks/29", :head => {
        'Accept' => 'application/vnd.bonfire+xml'
      })

      res = Restfully::HTTP::Response.new(@session, 200, {
        'Content-Type' => 'application/vnd.bonfire+xml'
      }, fixture("bonfire-network-existing.xml"))

      res.media_type.should be_a(
        Restfully::MediaType::ApplicationVndBonfireXml
      )

      resource = Restfully::Resource.new(@session, res, req).load

      resource.uri.to_s.should == "http://localhost:8000/locations/de-hlrs/networks/29"
      resource.collection?.should be_false
      resource.properties.should == {"name"=>"Private LAN", "public"=>"YES", "id"=>"29"}
    end

    it "should correctly load and iterate over a collection" do
      req = Restfully::HTTP::Request.new(@session, :get, "http://localhost:8000/experiments", :head => {
        'Accept' => 'application/vnd.bonfire+xml'
      })

      res = Restfully::HTTP::Response.new(@session, 200, {
        'Content-Type' => 'application/vnd.bonfire+xml'
      }, fixture("bonfire-experiment-collection.xml"))

      res.media_type.should be_a(Restfully::MediaType::ApplicationVndBonfireXml)

      collection = Restfully::Resource.new(@session, res, req).load

      collection.uri.to_s.should == "http://localhost:8000/experiments"
      collection.collection?.should be_true
      collection.length.should == 3
      collection.total.should == 3
      collection.offset.should == 0
      collection.all?{|i| i.kind_of? Restfully::Resource}.should be_true
      collection[0].should == collection.first
      collection[-1].uri.to_s.should == "http://localhost:8000/experiments/3"
      collection[-1].should == collection[2]
      collection[-1].should == collection.last
      collection[10].should be_nil
    end

    it "should correctly load an empty collection" do
      req = Restfully::HTTP::Request.new(@session, :get, "http://localhost:8000/locations/uk-epcc/computes", :head => {
        'Accept' => 'application/vnd.bonfire+xml'
      })

      res = Restfully::HTTP::Response.new(@session, 200, {
        'Content-Type' => 'application/vnd.bonfire+xml'
      }, fixture("bonfire-empty-collection.xml"))

      res.media_type.should be_a(Restfully::MediaType::ApplicationVndBonfireXml)

      collection = Restfully::Resource.new(@session, res, req).load
      collection.collection?.should be_true
      collection.length.should == 0
      collection.inspect.should == "[]"
      collection.should be_empty
    end

    it "should correctly load a collection with non-detailed items" do
      req = Restfully::HTTP::Request.new(@session, :get, "http://localhost:8000/locations/de-hlrs/networks", :head => {
        'Accept' => 'application/vnd.bonfire+xml'
      })

      res = Restfully::HTTP::Response.new(@session, 200, {
        'Content-Type' => 'application/vnd.bonfire+xml'
      }, fixture("bonfire-collection-with-fragments.xml"))

      collection = Restfully::Resource.new(@session, res, req).load
      collection.any?{|item| item.media_type.complete?}.should be_false
      collection.inspect.should == "[{...}]"

      stub_request(:get, "http://localhost:8000/locations/de-hlrs/networks/29").
        with(:headers => {'Accept'=>'application/vnd.bonfire+xml', 'Accept-Encoding'=>'gzip, deflate', 'Cache-Control'=>'no-cache'}).
        to_return(:status => 200, :body => fixture("bonfire-network-existing.xml"), :headers => {'Content-Type' => 'application/vnd.bonfire+xml'})
      network = collection[0]
      network.properties.should == {"name"=>"Private LAN", "public"=>"YES", "id"=>"29"}
    end
  end

  describe "serializing to xml" do
    it "should correctly serialize a resource" do
      ns = "occi:http://api.bonfire-project.eu/doc/schemas/occi"
      serialized = Restfully::MediaType::ApplicationVndBonfireXml.serialize(
        @expected_compute_hash,
        :serialization => {"__type__" => "compute"}
      )

      xml = XML::Document.string(serialized)
      xml.root.find_first("occi:name", ns).content.should == "Compute name"
      xml.root.find_first("occi:instance_type", ns).content.should == "small"
      nics = xml.root.find("occi:nic", ns)
      nics.length.should == 2
      nics[0]['id'].should == "0"
      nics[1]['id'].should == "1"
      nics[0].find_first("occi:mac", ns).content.should == "AA:AA:AA:AA"
      disks = xml.root.find("occi:disk", ns)
      disks.length.should == 2
      disks[1].find_first("occi:storage", ns)['href'].should == "/locations/fr-inria/storages/2"
      links = xml.root.find("occi:link", ns)
      links.length.should == 2
      links[0]['href'].should == "/locations/fr-inria"
      links[0]['type'].should == "application/vnd.bonfire+xml"
      xml.root.
        find_first('occi:context', ns).
        find_first('occi:bonfire_credentials', ns).content.should == "crohr:p4ssw0rd"
    end

    it "should correctly deal with XML::Node elements" do
      serialized = Restfully::MediaType::ApplicationVndBonfireXml.serialize({
        :context => {
          'metrics' => XML::Node.new_cdata('<metric>hello,world</metric>')
        }
      }, :serialization => {"__type__" => "compute"})
      serialized.split("\n").sort.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<compute xmlns=\"http://api.bonfire-project.eu/doc/schemas/occi\">\n  <context>\n    <metrics><![CDATA[<metric>hello,world</metric>]]></metrics>\n  </context>\n</compute>\n".split("\n").sort
    end

    it "should correctly deal with SAVE_AS elements" do
      serialized = Restfully::MediaType::ApplicationVndBonfireXml.serialize(
        {
          :name => "whatever",
          :disk => [{
            :save_as => {:name => "name of storage"},
            :storage => {"href" => "/somewhere"}
          }]
        },
        :serialization => {"__type__" => "compute"}
      )
      serialized.split("\n").sort.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<compute xmlns=\"http://api.bonfire-project.eu/doc/schemas/occi\">\n  <name>whatever</name>\n  <disk id=\"0\">\n    <save_as name=\"name of storage\"/>\n    <storage href=\"/somewhere\"/>\n  </disk>\n</compute>\n".split("\n").sort
    end
  end
end
