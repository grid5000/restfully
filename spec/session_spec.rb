require File.dirname(__FILE__)+'/spec_helper'

include Restfully
describe Session do

  it "should have a logger reader" do
    session = Session.new('https://api.grid5000.fr')
    session.should_not respond_to(:logger=)
    session.should respond_to(:logger)
  end
  it "should have a base_url reader" do
    session = Session.new('https://api.grid5000.fr')
    session.should_not respond_to(:base_url=)
    session.base_url.should == 'https://api.grid5000.fr'
  end
  
  it "should log to NullLogger by default" do
    NullLogger.should_receive(:new)
    session = Session.new('https://api.grid5000.fr')
  end
end