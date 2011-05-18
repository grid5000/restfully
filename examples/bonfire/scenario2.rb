#!/usr/bin/env ruby

require 'rubygems'
require 'pp'
require 'restfully'

session = Restfully::Session.new(
  :configuration_file => "~/.restfully/api.bonfire-project.eu"
)

experiment = nil

public_key = Dir[File.expand_path("~/.ssh/*.pub")].find{|key|
  File.exist?(key.gsub(/\.pub$/,""))
}
fail "Can't find a public SSH key, with its corresponding private key" if public_key.nil?

puts "Using public key located at #{public_key}."


begin
  experiment = session.root.experiments.submit(
    :name => "Scenario1",
    :description => "Demo of scenario2 using Restfully",
    :status => "waiting",
    :walltime => 4*3600 # 4 hours
  )

  location = session.root.locations[:'be-ibbt']
  fail "Can't select the be-ibbt location" if location.nil?

  disk = location.storages.find{|s| s['name'] == "SLES10.2-STD"}
  fail "Can't get one of the images" if disk.nil?

  network = experiment.networks.submit(
    :location => location,
    :name => "network-experiment##{experiment['id']}",
    :bandwidth => 100,
    :latency => 0,
    :size => 24,
    :lossrate => 0,
    # You MUST specify the address:
    :address => "172.18.4.0"
  )

  p "*****************"
  pp network

  compute1 = experiment.computes.submit(
    :name => "compute1-experiment##{experiment['id']}",
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
    :name => "compute2-experiment##{experiment['id']}",
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
  experiment.delete unless experiment.nil?
end
