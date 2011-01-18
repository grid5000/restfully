$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'webmock/rspec'
include WebMock

require 'restfully'
require 'spec'
require 'spec/autorun'
require 'json'


def fixture(filename)
  File.read(File.join(File.dirname(__FILE__), "fixtures", filename))
end

Spec::Runner.configure do |config|
  
end
