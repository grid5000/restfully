require 'spec_helper'

describe Restfully::HTTP::Helper do
  include Restfully::HTTP::Helper
  
  it "should correctly sanitize the headers" do
    sanitize_head({
      'Cache-control' => 'no-cache',
      :some_header => 'some value',
      'accept' => 'application/json'
    }).should == {
      'Cache-Control' => 'no-cache',
      'Some-Header' => 'some value',
      'Accept' => 'application/json'
    }
  end
  
end
