require 'rubygems'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'pp'

require File.dirname(__FILE__)+'/../lib/restfully'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN

# Restfully.adapter = Restfully::HTTP::RestClientAdapter
# Restfully.adapter = Patron::Session
RestClient.log = 'stdout'
Restfully::Session.new(:base_uri => 'http://api.local/sid/grid5000', :logger => logger) do |grid, session|
  grid_stats = {'hardware' => {}, 'system' => {}}
  grid.sites.each do |site|
    site_stats = site.status.inject({'hardware' => {}, 'system' => {}}) {|accu, node_status|
      accu['hardware'][node_status['hardware_state']] = (accu['hardware'][node_status['hardware_state']] || 0) + 1
      accu['system'][node_status['system_state']] = (accu['system'][node_status['system_state']] || 0) + 1
      accu
    } rescue {'hardware' => {}, 'system' => {}}
    grid_stats['hardware'].merge!(site_stats['hardware']) { |key,oldval,newval| oldval+newval }
    grid_stats['system'].merge!(site_stats['system']) { |key,oldval,newval| oldval+newval }
    p [site['uid'], site_stats]
  end
  p [:total, grid_stats]
  puts "Getting status of a few nodes in rennes:"
  pp grid.sites.find{|s| s['uid'] == 'rennes'}.status(:query => {:only => ['paradent-1', 'paradent-10', 'paramount-3']})
end
