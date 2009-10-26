require File.expand_path(File.dirname(__FILE__)+'/spec_helper')

describe Restfully do
  it "should have a default adapter" do
    Restfully.adapter.should == Restfully::HTTP::Adapters::RestClientAdapter
  end
  
  it "should allow setting other adapters" do
    require 'restfully/http/adapters/patron_adapter'
    Restfully.adapter = Restfully::HTTP::Adapters::PatronAdapter
    Restfully.adapter.should == Restfully::HTTP::Adapters::PatronAdapter
  end
end
