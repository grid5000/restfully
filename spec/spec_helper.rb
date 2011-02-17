require 'webmock/rspec'
require 'restfully'
require 'json'


def fixture(filename)
  File.read(File.join(File.dirname(__FILE__), "fixtures", filename))
end

RSpec.configure do |config|

  config.before(:each) do
    Restfully::MediaType.reset
  end

  # == Mock Framework
  config.mock_with :rspec

end
