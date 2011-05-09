require 'spec_helper'

describe Restfully::Resource do
  before do
    @session = Restfully::Session.new(
      :uri => "https://api.grid5000.fr"
    )
    @request = Restfully::HTTP::Request.new(
      @session, :get, "/grid5000/sites/rennes",
      :head => {'Accept' => 'application/vnd.grid5000+json'}
    )
    @response = Restfully::HTTP::Response.new(
      @session, 200, {
        'Content-Type' => 'application/vnd.grid5000+json; charset=utf-8',
        'Allow' => 'GET'
      }, fixture('grid5000-rennes.json')
    )
    Restfully::MediaType.register Restfully::MediaType::Grid5000
  end

  it "should correctly initialize a resource" do
    resource = Restfully::Resource.new(@session, @response, @request)
    resource.uri.to_s.should == "https://api.grid5000.fr/grid5000/sites/rennes"
    resource.should be_a(Restfully::Resource)
    resource.load.should == resource
    resource.media_type.should be_a(Restfully::MediaType::Grid5000)
    resource['uid'].should == 'rennes'
    %w{clusters jobs deployments status self parent}.each do |rel|
      resource.should respond_to(rel.to_sym)
    end
  end

  describe "loaded" do
    before do
      @resource = Restfully::Resource.new(@session, @response, @request)
      @resource.load
    end

    it "should load the requested association" do
      @session.should_receive(:get).once.with(
        URI.parse("/grid5000/sites/rennes/clusters"),
        :head=>{"Accept"=>"application/vnd.grid5000+json"}
      ).and_return(association=mock(Restfully::Resource))
      association.should_receive(:load)
      @resource.clusters
    end

    it "should not allow to submit if POST not allowed on the resource" do
      lambda{
        @resource.submit
      }.should raise_error(Restfully::MethodNotAllowed)
    end
    it "should send a POST request if POST is allowed [payload argument]" do
      @resource.should_receive(:allow?).with(:post).and_return(true)
      @session.should_receive(:post).with(
        @resource.uri,
        'some payload',
        :head => {'Content-Type' => 'text/plain'},
        :query => {:k1 => 'v1'},
        :serialization => {}
      )
      @resource.submit(
        'some payload',
        :headers => {'Content-Type' => 'text/plain'},
        :query => {:k1 => 'v1'}
      )
    end
    it "should send a POST request if POST is allowed [payload as hash]" do
      @resource.should_receive(:allow?).with(:post).and_return(true)
      @session.should_receive(:post).with(
        @resource.uri,
        {:key => 'value'},
        :head => {'Content-Type' => 'text/plain'},
        :query => {:k1 => 'v1'},
        :serialization => {}
      )
      @resource.submit(
        :key => 'value',
        :headers => {'Content-Type' => 'text/plain'},
        :query => {:k1 => 'v1'}
      )
    end
    it "should pass hidden properties as serialization parameters" do
      Restfully::MediaType.register Restfully::MediaType::ApplicationVndBonfireXml
      @request = Restfully::HTTP::Request.new(
        @session, :get, "/locations/de-hlrs/networks/29",
        :head => {'Accept' => 'application/vnd.bonfire+xml'}
      )
      @response = Restfully::HTTP::Response.new(
        @session, 200, {
          'Content-Type' => 'application/vnd.bonfire+xml; charset=utf-8',
          'Allow' => 'GET'
        }, fixture('bonfire-network-existing.xml')
      )
      @resource = Restfully::Resource.new(@session, @response, @request).load
      @resource.should_receive(:allow?).with(:put).and_return(true)
      @session.should_receive(:put).with(
        @resource.uri,
        {:key => 'value'},
        :head => {'Content-Type' => 'text/plain'},
        :query => {:k1 => 'v1'},
        :serialization => {"__type__"=>"network"}
      )
      @resource.update(
        :key => 'value',
        :headers => {'Content-Type' => 'text/plain'},
        :query => {:k1 => 'v1'}
      )
    end

    it "should reload the resource" do
      @request.should_receive(:no_cache!)
      @resource.should_receive(:load).
        and_return(@resource)
      @resource.reload.should == @resource
    end

    it "should reload the resource even after having reloaded it once before" do
      @session.should_receive(:execute).twice.with(@request).
        and_return(@response)
      @resource.reload
      @resource.reload
    end

    it "should raise an error if it cannot reload the resource" do
      @session.should_receive(:execute).with(@request).
        and_return(res=mock(Restfully::HTTP::Response))
      @session.should_receive(:process).with(res, @request).
        and_return(false)
      lambda{
        @resource.reload
      }.should raise_error(Restfully::Error, "Cannot reload the resource")
    end
  end

  describe "integration tests" do

    it "should not interfere with another previously loaded resource" do
      Restfully::MediaType.register Restfully::MediaType::ApplicationVndBonfireXml
      @session = Restfully::Session.new(
        :uri => "http://localhost:8000"
      )
      @request = Restfully::HTTP::Request.new(
        @session, :get, "/locations",
        :head => {'Accept' => 'application/vnd.bonfire+xml'}
      )
      @response = Restfully::HTTP::Response.new(
        @session, 200, {
          'Content-Type' => 'application/vnd.bonfire+xml; charset=utf-8',
          'Allow' => 'GET'
        }, fixture('bonfire-location-collection.xml')
      )

      resource = Restfully::Resource.new(@session, @response, @request).load
      resource1 = resource[:'uk-epcc']
      resource2 = resource[:'fr-inria']
      stub_request(:get, "http://localhost:8000/locations/uk-epcc/networks").
               with(:headers => {'Accept'=>'application/vnd.bonfire+xml', 'Accept-Encoding'=>'gzip, deflate'}).
               to_return(:status => 200, :body => fixture("bonfire-network-collection.xml"), :headers => {'Content-Type' => 'application/vnd.bonfire+xml'})
      stub_request(:get, "http://localhost:8000/locations/fr-inria/networks").
               with(:headers => {'Accept'=>'application/vnd.bonfire+xml', 'Accept-Encoding'=>'gzip, deflate'}).
               to_return(:status => 200, :body => fixture("bonfire-network-collection.xml"), :headers => {'Content-Type' => 'application/vnd.bonfire+xml'})
      resource1.networks
      resource2.networks
    end

  end # describe "integration tests"

end
