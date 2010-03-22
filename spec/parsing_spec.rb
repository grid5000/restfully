require File.expand_path(File.dirname(__FILE__)+'/spec_helper')

include Restfully::Parsing

describe Restfully::Parsing do
  class IncludesParsingModule
    include Restfully::Parsing
  end
  it "should make available the serialize and unserialize methods" do
    klass = IncludesParsingModule.new
    klass.should respond_to(:unserialize)
    klass.should respond_to(:serialize)
  end
  it "should raise a ParserNotFound error if the object cannot be parsed" do
    lambda{unserialize("whatever", :content_type => 'unknown')}.should raise_error(Restfully::Parsing::ParserNotFound, "Cannot find a parser to parse 'unknown' content.")
  end
  it "should correctly unserialize json content" do
    object = {'p1' => 'v1'}
    unserialize(object.to_json, :content_type => 'application/json;charset=utf-8').should == object
  end
  it "should correctly serialize an object into json" do
    object = {'p1' => 'v1'}
    serialize(object, :content_type => 'application/json;charset=utf-8').should == object.to_json
  end
  it "should correctly unserialize text content" do
    object = "anything"
    unserialize(object, :content_type => 'text/plain;charset=utf-8').should == object
  end
  it "should allow to define its own parser" do
    Restfully::Parsing::PARSERS.push({
      :supported_types => "text/unknown",
      :parse => lambda{|object, options| object.gsub(/x/, "y")},
      :dump => lambda{|object, options| object.gsub(/y/, "x")}
    })
    object = "xyz"
    parsed = unserialize(object, :content_type => 'text/unknown')
    parsed.should == "yyz"
    serialize(parsed, :content_type => 'text/unknown').should == "xxz"
  end
end