require 'spec_helper'

describe Restfully::MediaType do
  class NewMediaType < Restfully::MediaType::AbstractMediaType
    set :signature, "application/whatever"
    set :parser, JSON
  end
  class BadMediaType < Restfully::MediaType::AbstractMediaType; end

  describe "class methods" do
    it "should refuse to add a media type without signature" do
      lambda{
        Restfully::MediaType.register BadMediaType
      }.should raise_error(ArgumentError, "The given MediaType (BadMediaType) has no signature")
    end
    it "should refuse to add a media type without parser" do
      BadMediaType.set :signature, "application/whatever"
      lambda{
        Restfully::MediaType.register BadMediaType
      }.should raise_error(ArgumentError, "The given MediaType (BadMediaType) has no parser")
    end
    it "should add the media_type to the catalog" do
      length_before = Restfully::MediaType.catalog.length
      Restfully::MediaType.register NewMediaType
      Restfully::MediaType.catalog.length.should == length_before+1
    end

    it "should find the corresponding media_type" do
      Restfully::MediaType.register Restfully::MediaType::ApplicationJson
      Restfully::MediaType.find("application/json").should == Restfully::MediaType::ApplicationJson
    end

    it "should find the corresponding media_type" do
      Restfully::MediaType.register Restfully::MediaType::Grid5000
      Restfully::MediaType.find('application/vnd.grid5000+json; charset=utf-8').should == Restfully::MediaType::Grid5000
    end

    it "should fall back to wildcard" do
      Restfully::MediaType.find("whatever/whatever").should == Restfully::MediaType::Wildcard
    end
  end

  describe Restfully::MediaType::Wildcard do
    ["text/plain", "text/*", "*/*"].each do |type|
      it "should match everything [#{type}]" do
        Restfully::MediaType::Wildcard.supports?(type).should == "*/*"
      end
    end
    it "should not match invalid content types" do
      Restfully::MediaType::Wildcard.supports?("whatever").should be_nil
    end
    it "should correctly initialize with a payload" do
      media_type = Restfully::MediaType::Wildcard.new("some string")
      media_type.property("some").should == "some"
      media_type.links.should == []
    end
  end

  describe Restfully::MediaType::Grid5000 do
    before do
      @media_type =  Restfully::MediaType::Grid5000.new(
        StringIO.new(fixture('grid5000-rennes.json'))
      )
    end
    it "should correctly extract the links" do
      @media_type.links.map(&:rel).should == ["self", "parent", "versions", "clusters", "environments", "jobs", "deployments", "metrics", "status"]
      @media_type.links.map(&:title).should == ["self", "parent", "versions", "clusters", "environments", "jobs", "deployments", "metrics", "status"]
    end

    it "should correctly find a property" do
      @media_type.property("uid").should == "rennes"
    end

    it "should tell if it is a collection" do
      @media_type.collection?.should be_false
    end
  end

  describe Restfully::MediaType::ApplicationXWwwFormUrlencoded do
    before do
      @unserialized = {"k1" => 'value', "k2" => ['a','b','c']}
      @serialized = "k1=value&k2[]=a&k2[]=b&k2[]=c"
    end
    it "should have the correct default type" do
      Restfully::MediaType::ApplicationXWwwFormUrlencoded.
        default_type.should == "application/x-www-form-urlencoded"
    end
    it "should be found" do
      Restfully::MediaType.register Restfully::MediaType::ApplicationXWwwFormUrlencoded
      Restfully::MediaType.find('application/x-www-form-urlencoded').
        should == Restfully::MediaType::ApplicationXWwwFormUrlencoded
    end
    it "should correctly encode a hash" do
      Restfully::MediaType::ApplicationXWwwFormUrlencoded.
        serialize(@unserialized).should == @serialized
    end
    it "should correctly decode a string" do
      Restfully::MediaType::ApplicationXWwwFormUrlencoded.
        unserialize(@serialized).should == @unserialized
    end
  end

end
