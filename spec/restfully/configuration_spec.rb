require 'spec_helper'

describe Restfully::Configuration do

  before do
    @config_file = File.expand_path("../../fixtures/config.yml", __FILE__)
    @expected_merge = {
      :require=>["ApplicationVndBonfireXml", "something"], 
      :username=>"crohr", 
      :gateway=>"ssh.bonfire.grid5000.fr", 
      :uri=>"https://api.bonfire-project.eu/", 
      :password=>"p4ssw0rd"
    }
  end

  it "should take a hash and store it with symbolized keys" do
    config = Restfully::Configuration.new("a" => 1, :b => "hello", "c" => [1,2,3])
    config.options.should == {:a=>1, :b=>"hello", :c=>[1, 2, 3]}
  end

  it "should correctly load a configuration file" do
    config = Restfully::Configuration.load(@config_file)
    config.options.should == {
      :require=>["ApplicationVndBonfireXml"], 
      :username=>"someone", 
      :uri=>"https://api.bonfire-project.eu/", 
      :password=>"p4ssw0rd", 
      :gateway=>"ssh.bonfire.grid5000.fr"
    }
  end
  
  it "should correctly overwrite the options defined in the configuration file with other options given on initialization" do
    config = Restfully::Configuration.new(:username => "crohr", :require => ['something'], :configuration_file => @config_file)
    config.expand
    config.options.should == @expected_merge.merge(
      :configuration_file=>@config_file
    )
  end
  
  it "should correctly merge two configs" do
    config1 = Restfully::Configuration.new(:username => "crohr", :require => ['something'])
    config2 = Restfully::Configuration.load(@config_file)
    config2.merge(config1).options.should == @expected_merge
  end
end