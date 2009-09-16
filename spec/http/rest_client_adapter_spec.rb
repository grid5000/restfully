require File.dirname(__FILE__)+'/../spec_helper'
describe Restfully::HTTP::Adapters::RestClientAdapter do
  it "should correctly get the resource corresponding to the request" do
    adapter = Restfully::HTTP::Adapters::RestClientAdapter.new("https://api.grid5000.fr", :user => 'crohr', :password => 'password')
    request = Restfully::HTTP::Request.new('http://api.local/sid/grid5000', :headers => {:accept => 'application/json'}, :query => {:q1 => 'v1'})
    RestClient::Resource.should_receive(:new).with('http://api.local/sid/grid5000?q1=v1', :password => 'password', :user => 'crohr').and_return(resource = mock("restclient resource"))
    resource.should_receive(:get).with(request.headers).and_return(mock("restclient response", :headers => {:content_type => 'application/json;charset=utf-8', :status => 200}, :to_s => ""))
    response = adapter.get(request)
    response.status.should == 200
    response.body.should be_nil
    response.headers.should == {
      'Content-Type' => 'application/json;charset=utf-8'
    }
  end
  it "should raise a not implemented error when trying to use functions not implemented yet" do
    adapter = Restfully::HTTP::Adapters::RestClientAdapter.new("https://api.grid5000.fr")
    lambda{adapter.post(mock("restfully request"))}.should raise_error NotImplementedError, "POST is not supported by your adapter."
  end
end