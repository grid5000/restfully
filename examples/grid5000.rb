require 'rubygems'
require 'restfully'
require 'pp'

Restfully::Session.new(
  :configuration_file => '~/.restfully/api.grid5000.fr.yml'
) do |grid, session|
  grid_stats = {'hardware' => {}, 'system' => {}}

  grid.sites.each do |site|
    site_stats = site.status.inject({
      'hardware' => {},
      'system' => {}
    }) {|accu, node_status|
      accu['hardware'][node_status['hardware_state']] = (accu['hardware'][node_status['hardware_state']] || 0) + 1
      accu['system'][node_status['system_state']] = (accu['system'][node_status['system_state']] || 0) + 1
      accu
    } rescue {'hardware' => {}, 'system' => {}}

    grid_stats['hardware'].merge!(site_stats['hardware']) { |key,oldval,newval|
      oldval+newval
    }

    grid_stats['system'].merge!(site_stats['system']) { |key,oldval,newval|
      oldval+newval
    }
    p [site['uid'], site_stats]
  end

  p [:total, grid_stats]

  puts "Getting status of a few nodes in rennes:"
  pp grid.sites[:rennes].status(
    :query => {
      :only => ['paradent-1', 'paradent-10', 'paramount-3'].join(",")
    }
  )
end
