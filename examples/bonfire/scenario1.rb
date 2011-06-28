#!/usr/bin/env ruby

require 'rubygems'
require 'pp'
require 'restfully'

# Here we use a configuration file to avoid putting our BonFIRE credentials in the source file.
# See <http://wiki.bonfire-project.eu/index.php/Restfully#FAQ> to learn how to create that configuration file, or at the end of that script.
session = Restfully::Session.new(
  :configuration_file => "~/.restfully/api.bonfire-project.eu",
  :cache => false
)
session.logger.level = Logger::INFO

experiment = nil

begin
  experiment = session.root.experiments.submit(
    :name => "Scenario1",
    :description => "Demo of scenario1 using Restfully",
    :walltime => 4*3600 # 4 hours
  )

  location1 = session.root.locations[:'fr-inria']
  fail "Can't select the fr-inria location" if location1.nil?
  location2 = session.root.locations[:'de-hlrs']
  fail "Can't select the de-hlrs location" if location2.nil?

  server_image = location1.storages.find{|s| s['name'] == "BonFIRE Debian Squeeze 2G v1"}
  client_image = location2.storages.find{|s| s['name'] == "BonFIRE Debian Squeeze 2G v1"}
  fail "Can't get one of the images" if server_image.nil? || client_image.nil?

  network_location1 = location1.networks.find{|n| n['name'] == 'BonFIRE WAN'}
  fail "Can't select the public network in fr-inria" if network_location1.nil?

  network_location2 = location2.networks.find{|n| n['name'] == 'BonFIRE WAN'}
  fail "Can't select the network in de-hlrs" if network_location2.nil?

  server = experiment.computes.submit(
    :name => "server-experiment#{experiment['id']}",
    :instance_type => "small",
    :disk => [
      {:storage => server_image, :type => "OS"}
    ],
    :nic => [
      {:network => network_location1}
    ],
    :location => location1
  )

  client = experiment.computes.submit(
    :name => "client-experiment#{experiment['id']}",
    :instance_type => "small",
    :disk => [
      {:storage => client_image, :type => "OS"}
    ],
    :nic => [
      {:network => network_location2}
    ],
    :location => location2,
    :context => {
       'server_ip' => server.reload['nic'][0]['ip']
     }
  )

  # Display VM IPs
  puts "*** Server IP:"
  puts server.reload['nic'][0]['ip']
  
  puts "*** Client IP:"
  puts client.reload['nic'][0]['ip']

  # Control loop, until the experiment is done.
  until ['terminated', 'canceled'].include?(experiment.reload['status']) do
    p server.reload
    p client.reload
    
    case experiment['status']
    when 'running'
      puts "Experiment is running. Nothing to do..."
    when 'terminating'
      # Here you could save_as, send a notification, etc.
      # Here for example, we save the first disk of the client VM as a new image:
      client.update(:disk => [
        {:save_as => {:name => "saved-#{client['name']}-image"}}
      ])
    else
      puts "Experiment is #{experiment['status']}. Nothing to do yet."
    end
    sleep 15
  end
  
  puts "Experiment terminated!"

rescue Exception => e
  puts "[ERROR] #{e.class.name}: #{e.message}"
  puts e.backtrace.join("\n")
  puts "Cleaning up in 5 seconds. Hit CTRL-C now to keep your VMs..."
  sleep 5
  experiment.delete unless experiment.nil?
end

__END__

$ cat ~/.restfully/api.bonfire-project.eu
uri: https://api.bonfire-project.eu:444/
username: crohr
password: PASSWORD
require:
  - ApplicationVndBonfireXml
