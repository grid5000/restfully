require File.expand_path(File.dirname(__FILE__)+'/../spec_helper')
describe Restfully::HTTP::Request do

  it "should correctly initialize the attributes" do
    request = Restfully::HTTP::Request.new(
      'https://api.grid5000.fr/sid/grid5000?q1=v1&q2=v2', 
      :headers => {'accept' => 'application/json', :cache_control => 'max-age=0', 'Content-Type' => 'application/json'}, 
      :query => {'custom_param1' => [3, 4, 5, 6], 'custom_param2' => 'value_custom_param2'},
      :body => {"key" => "value"}.to_json
    )
    request.uri.should be_a URI
    request.uri.to_s.should == 'https://api.grid5000.fr/sid/grid5000?q1=v1&q2=v2&custom_param1=3,4,5,6&custom_param2=value_custom_param2'
    request.uri.query.should == "q1=v1&q2=v2&custom_param1=3,4,5,6&custom_param2=value_custom_param2"
    request.headers.should == {
      "Content-Type"=>"application/json", 
      'Accept' => 'application/json',
      'Cache-Control' => 'max-age=0'
    }
    request.body.should == {"key" => "value"}
    request.raw_body.should == "{\"key\":\"value\"}"
    request.retries.should == 0
  end
  
  it "should accept a URI object as url" do
    request = Restfully::HTTP::Request.new(uri=URI.parse('https://api.grid5000.fr/sid/grid5000'))
    request.uri.to_s.should == 'https://api.grid5000.fr/sid/grid5000'
  end
  
  it "should not fail if there are query parameters but no query string in the given URL" do
    request = Restfully::HTTP::Request.new('https://api.grid5000.fr/grid5000', :query => {:q1 => 'v1'})
    request.uri.query.should == "q1=v1"
  end
  
  it "should not change the query string if none is given as an option" do
    request = Restfully::HTTP::Request.new('https://api.grid5000.fr/grid5000?q1=v1&q2=v2')
    request.uri.to_s.should == 'https://api.grid5000.fr/grid5000?q1=v1&q2=v2'
    request.headers.should == {}
  end
  
  it "should offer a function to add headers" do
    request = Restfully::HTTP::Request.new('https://api.grid5000.fr/grid5000?q1=v1&q2=v2', :headers => {:accept => 'application/json'})
    expected_headers = {
      'Accept' => 'application/json',
      'Cache-Control' => 'max-age=0'
    }
    request.add_headers(:cache_control => 'max-age=0').should == expected_headers
    request.headers.should == expected_headers
  end
end