require 'rubygems'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'pp'

require File.dirname(__FILE__)+'/../lib/restfully'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

RestClient.log = 'stdout'

# This yaml file contains the following attributes:
# username: my_username
# password: my_password
options = YAML.load_file(File.expand_path('~/.restfully/api.grid5000.fr.yml')) 
options[:uri] = 'https://api.grid5000.fr/sid/grid5000'
options[:logger] = logger
Restfully::Session.new(options) do |grid, session|
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
