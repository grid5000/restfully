require 'rubygems'
require 'pp'

require File.dirname(__FILE__)+'/../lib/restfully'

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

# Restfully.adapter = Restfully::HTTP::RestClientAdapter
# Restfully.adapter = Patron::Session
RestClient.log = 'stdout'
Restfully::Session.new('https://localhost:3443/sid', 'root' => '/versions/current', 'logger' => logger) do |grid, session|
  grid_stats = {'hardware' => {}, 'system' => {}}
  grid.sites.each do |site_uid, site|
    site_stats = site.status.inject({'hardware' => {}, 'system' => {}}) {|accu, (node_uid, node_status)|
      accu['hardware'][node_status['hardware_state']] = (accu['hardware'][node_status['hardware_state']] || 0) + 1
      accu['system'][node_status['system_state']] = (accu['system'][node_status['system_state']] || 0) + 1
      accu
    }
    grid_stats['hardware'].merge!(site_stats['hardware']) { |key,oldval,newval| oldval+newval }
    grid_stats['system'].merge!(site_stats['system']) { |key,oldval,newval| oldval+newval }
    p [site_uid, site_stats]
  end
  p [:total, grid_stats]
  puts "Getting status of a few nodes in rennes:"
  pp grid.sites['rennes'].status(:query => {:only => ['paradent-1', 'paradent-10', 'paramount-3']})
  
  # TODO: Auto discovery of allowed HTTP methods: create raises an error if not available, otherwise POSTs the given object (and auto-select the content-type)
  # grid.sites["rennes"].jobs.create({:walltime => 120, :whatever => ''})
end