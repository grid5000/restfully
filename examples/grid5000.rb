require 'rubygems'
require 'pp'

require File.dirname(__FILE__)+'/../lib/restfully'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

Restfully::Session.new('http://reference-api.local', 'root' => '/versions/current', 'logger' => logger) do |grid, session|
  logger.info grid.associations
  # should also support "implied guid" such as :rennes, :paramount, etc.
  grid.sites['/sites/rennes'].clusters.each do |cluster_guid, cluster|
    logger.info cluster.associations
    pp [cluster_guid, cluster.nodes.length]
    # pp cluster.status
    # cluster.nodes.each do |node_guid, node|
    #   pp node.metrics["#{node_guid}/metrics/mem_free"]
    # end
  end
  grid.sites[:rennes].clusters[:paramount].nodes.each do |node_guid, node|
    pp node_guid
  end
  
  # TODO: Auto discovery of allowed HTTP methods: create raises an error if not available, otherwise POSTs the given object (and auto-select the content-type)
  # grid.sites[:rennes].jobs.create({:walltime => 120, :whatever => ''})
end