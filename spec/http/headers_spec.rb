require File.dirname(__FILE__)+'/../spec_helper'
describe Restfully::HTTP::Headers do
  class IncludeHeadersModule
    include Restfully::HTTP::Headers
  end
  
  it "should correctly parse headers" do
    sanitized_headers = IncludeHeadersModule.new.sanitize_http_headers('accept' => 'application/json', :x_remote_ident => 'crohr', 'X_GVI' => 'sid', 'CACHE-CONTROL' => ['max-age=0', 'no-cache'], 'Content-Length' => 22)
    sanitized_headers.should == {
      'Accept' => 'application/json',
      'X-Remote-Ident' => 'crohr',
      'X-Gvi' => 'sid',
      'Cache-Control' => 'max-age=0, no-cache',
      'Content-Length' => 22
    }
  end
end