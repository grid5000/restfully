require File.dirname(__FILE__)+'/../spec_helper'
describe Restfully::HTTP::Error do
  it "should have a response reader" do
    response = mock("restfully response", :status => 404, :body => {'title' => 'Not Found', 'message' => 'The requested resource cannot be found.', 'code' => 404})
    error = Restfully::HTTP::Error.new(response)
    error.response.should == response
  end
  it "should work properly" do
    response = mock("restfully response", :status => 404, :body => {'title' => 'Not Found', 'message' => 'The requested resource cannot be found.', 'code' => 404})
    begin
      raise Restfully::HTTP::Error.new(response)
    rescue Restfully::HTTP::Error => e
      e.response.should == response
      e.message.should == "404 Not Found. The requested resource cannot be found."
      e.backtrace.should_not be_empty
    end
  end
end