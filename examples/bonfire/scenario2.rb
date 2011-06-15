#!/usr/bin/env ruby

require 'rubygems'
require 'pp'
require 'restfully'

session = Restfully::Session.new(
  :configuration_file => ENV['RESTFULLY_CONFIG'] || "~/.restfully/api.bonfire-project.eu"
)

experiment = nil

begin
  experiment = session.root.experiments.submit(
    :name => "Scenario1",
    :description => "Demo of scenario2 using Restfully",
    # For VW experiments, you MUST explicitly specify the status to "waiting".
    # Then, after you created your resources, you MUST update the experiment 
    # and pass its status to "running" (see below).
    :status => "waiting",
    :walltime => 4*3600 # 4 hours
  )

  location = session.root.locations[:'be-ibbt']
  fail "Can't select the be-ibbt location" if location.nil?

  disk = location.storages.find{|s| s['name'] == "BonFIRE Debian Squeeze v1"}
  fail "Can't get one of the images" if disk.nil?
  
  network = location.networks.find{|s| s['name'] == "BonFIRE WAN"}
  fail "Can't get the BonFIRE WAN network" if network.nil?

  # If you wanted to submit a custom network, here is how you would do it:
  # network = experiment.networks.submit(
  #   :location => location,
  #   :name => "network-experiment#{experiment['id']}",
  #   :bandwidth => 100,
  #   :latency => 0,
  #   :size => 24,
  #   :lossrate => 0,
  #   # You MUST specify the address:
  #   :address => "192.168.0.1"
  # )

  puts "*****************"
  pp network

  compute1 = experiment.computes.submit(
    :name => "compute1-experiment#{experiment['id']}",
    :instance_type => "small",
    :disk => [
      {:storage => disk, :type => "OS"}
    ],
    :nic => [
      {:network => network}
    ],
    :location => location
  )

  compute2 = experiment.computes.submit(
    :name => "compute2-experiment#{experiment['id']}",
    :instance_type => "small",
    :disk => [
      {:storage => disk, :type => "OS"}
    ],
    :nic => [
      {:network => network}
    ],
    :location => location
  )

  pp compute1.reload
  pp compute2.reload

  # Pass experiment to "running":
  experiment.update(:status => "running")

  pp experiment.reload

  # Control loop, until the experiment is done.
  until ['terminated', 'canceled'].include?(experiment.reload['status']) do
    case experiment['status']
    when 'running'
      puts "Experiment is running. Nothing to do..."
    when 'terminating'
      puts "Experiment will terminate very soon..."
    else
      puts "Experiment is #{experiment['status']}. Nothing to do yet."
    end
    sleep 5
  end

rescue Exception => e
  puts "[ERROR] #{e.class.name}: #{e.message}"
  puts e.backtrace.join("\n")
  puts "Cleaning up..."
  sleep 5
  experiment.delete unless experiment.nil?
end
