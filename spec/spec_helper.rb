$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'restfully'
require 'spec'
require 'spec/autorun'

def fixture(filename)
  File.read(File.join(File.dirname(__FILE__), "fixtures", filename))
end

Spec::Runner.configure do |config|
  
end
