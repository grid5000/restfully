require File.dirname(__FILE__)+'/../spec_helper'
describe Restfully::HTTP::Adapters::RestClientAdapter do
  it "should correctly get the resource corresponding to the request" do
    adapter = Restfully::HTTP::Adapters::RestClientAdapter.new("https://api.grid5000.fr", :username => 'crohr', :password => 'password')
    request = Restfully::HTTP::Request.new('http://api.local/sid/grid5000', :headers => {:accept => 'application/json'}, :query => {:q1 => 'v1'})
    RestClient::Resource.should_receive(:new).with('http://api.local/sid/grid5000?q1=v1', :password => 'password', :user => 'crohr').and_return(resource = mock("restclient resource"))
    resource.should_receive(:get).with(request.headers).and_return(mock("restclient response", :headers => {:content_type => 'application/json;charset=utf-8'}, :to_s => "", :code => 200))
    response = adapter.get(request)
    response.status.should == 200
    response.body.should be_nil
    response.headers.should == {
      'Content-Type' => 'application/json;charset=utf-8'
    }
  end
  it "should transform the username option into a user option" do
    adapter = Restfully::HTTP::Adapters::RestClientAdapter.new("https://api.grid5000.fr", :username => 'crohr', :password => 'password')
    adapter.options[:user].should == 'crohr'
    adapter.options[:username].should be_nil
  end
  it "should raise a not implemented error when trying to use functions not implemented yet" do
    adapter = Restfully::HTTP::Adapters::RestClientAdapter.new("https://api.grid5000.fr")
    lambda{adapter.post(mock("restfully request"))}.should raise_error NotImplementedError, "POST is not supported by your adapter."
  end
  it "should rescue any RestClient::Exception and correctly populate the response" do
    res = mock(Net::HTTPResponse, :code => 404, :body => '{"message":"whatever"}', :to_hash => {'Content-Type' => 'application/json;charset=utf-8', 'Content-Length' => 22}, :[] => '')
    RestClient::Resource.should_receive(:new).and_raise RestClient::ResourceNotFound.new(res)
    adapter = Restfully::HTTP::Adapters::RestClientAdapter.new("https://api.grid5000.fr", :username => 'crohr', :password => 'password')
    response = adapter.get(mock("request", :uri => "uri"))
    response.status.should == 404
    response.headers.should == {'Content-Type' => 'application/json;charset=utf-8', 'Content-Length' => 22}
    response.body.should == {'message' => 'whatever'}
  end
end