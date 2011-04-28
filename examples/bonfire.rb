# Tested under ruby1.9.
# Install the following ruby gems:
#
#   gem install restfully --prerelase
#   gem install libxml-ruby
#

require 'pp'
begin
  retried = false
  require 'restfully'
rescue LoadError
  $LOAD_PATH.unshift(File.dirname(__FILE__)+'/../lib')
  retry unless retried
end

# Require BonFIRE media-type.
require 'restfully/media_type/application_vnd_bonfire_xml'

logger = Logger.new(STDERR)
logger.level = Logger::WARN

Restfully::Session.new(
  :uri => 'http://localhost:8081', 
  :default_headers => {
    'Content-Type' => 'application/vnd.bonfire+xml',
    'X-Bonfire-Asserted-Id' => 'crohr'
  },
  :logger => logger
) do |root, session|

  fr_inria = root.locations[:'fr-inria']

  puts "Creating a new experiment..."
  experiment = root.experiments.submit(
    :name => 'experiment xyz', 
    :description => 'my description'
  )
  
  pp experiment

  puts "Creating a new compute resource..."
  compute = experiment.computes.submit(
    :name => "compute name",
    :instance_type => "small",
    :location => fr_inria,
    :nic => [
      {
        :network => fr_inria.networks.find{|s| s["public"] == "YES"}
      }
    ],
    :disk => [
      {
        :storage => fr_inria.storages.find{|s| s["public"] == "YES"},
        :type => "OS"
      }
    ],
    :context => {
      'PUBLIC_SSH_KEY' => File.read(File.expand_path("~/.ssh/id_rsa.pub"))
    }
  )
  
  pp compute

  until compute.reload['state'] == 'running'
    puts "Waiting for compute##{compute['id']} to be running (current state=#{compute['state']})..."
    sleep 5
  end
  
  puts "Compute##{compute['id']} is now running."

  pp compute
end
