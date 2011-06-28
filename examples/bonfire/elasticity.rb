#!/usr/bin/env ruby

# This is an example of an end to end scenario, with support for saving images 
# at the end of the experiment, and interacting with the BonFIRE API from the
# VMs.

require 'rubygems'
require 'timeout'
require 'pp'
require 'restfully'
require 'net/ssh/gateway' # gem install net-ssh-gateway

# Here we use a configuration file to avoid putting our BonFIRE credentials in the source file.
# See <http://wiki.bonfire-project.eu/index.php/Restfully#FAQ> to learn how to create that configuration file, or at the end of that script.
session = Restfully::Session.new(
  :configuration_file => "~/.restfully/api.bonfire-project.eu"
)
session.logger.level = Logger::INFO

if ENV['DEBUG']
  require 'examples/bonfire/helpers/http'
  session.enable Rack::HTTPLogger, :log_file => ENV['DEBUG']
end

experiment = nil
@gw_user = session.config[:username] || ENV['USER']

# Helper function to deal with SSH connections
def ssh(host, user, options = {}, &block)
  gateway = Net::SSH::Gateway.new('ssh.bonfire.grid5000.fr', @gw_user, :forward_agent => true)
  puts "Trying to SSH into #{user}@#{host}..."
  gateway.ssh(host, user, &block)
  gateway.shutdown!
end

def ssh_accessible?(host)
  Timeout.timeout(30) do
    ssh(host, 'root') {|s| s.exec!("hostname") }
  end
  true
rescue Exception => e
  puts "Can't SSH yet to #{host}. Reason: #{e.class.name}, #{e.message}."
  false
end

begin
  experiment = session.root.experiments.submit(
    :name => "Scenario1",
    :description => "Demo of scenario1 using Restfully",
    :walltime => 3600
  )

  aggregator_location = session.root.locations[:'fr-inria']
  fail "Can't select the fr-inria location" if aggregator_location.nil?
  client_location = session.root.locations[:'uk-epcc']
  fail "Can't select the de-hlrs location" if client_location.nil?
  server_location = session.root.locations[:'fr-inria']
  fail "Can't select the uk-epcc location" if server_location.nil?

  
  aggregator_image = aggregator_location.storages.find{|s| s['name'] =~ /BonFIRE Zabbix Aggregator v2/i}
  client_image = client_location.storages.find{|s| s['name'] =~ /BonFIRE Debian Squeeze v1/i}
  server_image = server_location.storages.find{|s| s['name'] =~ /BonFIRE Debian Squeeze 2G v1/i}
  fail "Can't get one of the images" if server_image.nil? || client_image.nil? || aggregator_image.nil?

  aggregator_network = aggregator_location.networks.find{|n| n['public'] == 'YES' && n['name'] == 'Public Network'}
  fail "Can't select the aggregator network" if aggregator_network.nil?

  client_network = client_location.networks.find{|n| n['public'] == 'YES'}
  fail "Can't select the client network" if client_network.nil?
  
  server_network = server_location.networks.find{|n| n['public'] == 'YES' && n['name'] == 'Public Network'}
  fail "Can't select the server network" if server_network.nil?

  aggregator = experiment.computes.submit(
    :name => "BonFIRE-monitor-experiment#{experiment['id']}",
    :instance_type => "small",
    :disk => [
      {:storage => aggregator_image, :type => "OS"}
    ],
    :nic => [
      {:network => aggregator_network}
    ],
    :location => aggregator_location
  )
  aggregator_ip = aggregator['nic'][0]['ip']

  server = experiment.computes.submit(
    :name => "server-experiment#{experiment['id']}",
    :instance_type => "small",
    :disk => [
      {:storage => server_image, :type => "OS"}
    ],
    :nic => [
      {:network => server_network}
    ],
    :location => server_location,
    :context => {
      'aggregator_ip' => aggregator_ip
    }
  )
  server_ip = server['nic'][0]['ip']

  client = experiment.computes.submit(
    :name => "client-experiment#{experiment['id']}",
    :instance_type => "small",
    :disk => [
      {:storage => client_image, :type => "OS"}
    ],
    :nic => [
      {:network => client_network}
    ],
    :location => client_location,
    :context => {
      'server_ip' => server_ip,
      'aggregator_ip' => aggregator_ip
    }
  )
  client_ip = client['nic'][0]['ip']

  # Display VM IPs
  puts "*** Aggregator IP:"
  puts aggregator_ip

  puts "*** Server IP:"
  puts server_ip

  puts "*** Client IP:"
  puts client_ip

  until server.reload['state'] == 'ACTIVE' && client.reload['state'] == 'ACTIVE' do
    puts "One of the VMs is not ACTIVE. Waiting..."
    sleep 10
  end

  until [aggregator_ip,server_ip,client_ip].all?{|ip| ssh_accessible?(ip)}
    sleep 10
  end
  
  puts "VMs are now READY"

  ssh(server_ip, 'root') do |handler|
    puts handler.exec!("hostname")
    puts handler.exec!("DEBIAN_FRONTEND=noninteractive apt-get install curl -y")
    # Here we show how one can fetch the full description of the current VM via the BonFIRE API:
    puts handler.exec!("source /etc/default/bonfire && curl -k $BONFIRE_URI/locations/$BONFIRE_PROVIDER/computes/$BONFIRE_RESOURCE_ID -u $BONFIRE_CREDENTIALS")
  end

  ssh(aggregator_ip, 'root') do |handler|
    puts handler.exec!("hostname")
  end
  
  # ssh(client_ip, 'root') do |handler|
  #   puts handler.exec!("wget http://#{server_ip}/")
  # end

  # Control loop, until the experiment is done.
  until ['terminated', 'canceled'].include?(experiment.reload['status']) do
    case experiment['status']
    when 'running'
      puts "Experiment is running. Nothing to do..."
    when 'terminating'
      client.reload
      # Here you could save_as, send a notification, etc.
      # Here for example, we save the first disk of the client VM as a new image:
      unless client['disk'][0]['save_as']
        client.update(:disk => [
          {:save_as => {:name => "saved-#{client['name']}-image"}}
        ])
      end
    else
      puts "Experiment is #{experiment['status']}. Nothing to do yet."
    end
    sleep 30
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
