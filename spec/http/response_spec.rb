require File.expand_path(File.dirname(__FILE__)+'/../spec_helper')
describe Restfully::HTTP::Response do

  it "should correctly initialize the attributes" do
    response = Restfully::HTTP::Response.new(404, {:content_type => 'application/json;charset=utf-8'}, '{"property1": "value1", "property2": "value2"}')
    response.status.should == 404
    response.headers.should == {
      'Content-Type' => 'application/json;charset=utf-8'
    }
    response.body.should == {
      'property1' => 'value1',
      'property2' => 'value2'
    }
  end
  it "should return the unserialized body" do
    response = Restfully::HTTP::Response.new(404, {:content_type => 'application/json;charset=utf-8'}, '{"property1": "value1", "property2": "value2"}')
    response.raw_body.should == "{\"property1\": \"value1\", \"property2\": \"value2\"}"
  end
end