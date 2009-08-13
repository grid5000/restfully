require File.dirname(__FILE__)+'/spec_helper'

include Restfully
describe Link do

  it "should have a rel reader" do
    link = Link.new
    link.should_not respond_to(:rel=)
    link.should respond_to(:rel)
  end
  it "should have a href reader" do
    link = Link.new
    link.should_not respond_to(:href=)
    link.should respond_to(:href)
  end
  it "should have a title reader" do
    link = Link.new
    link.should_not respond_to(:title=)
    link.should respond_to(:title)
  end
  it "should have a errors reader" do
    link = Link.new
    link.should_not respond_to(:errors=)
    link.should respond_to(:errors)
  end
  it "should respond to valid?" do
    link = Link.new
    link.should respond_to(:valid?)    
  end
  it "should respond to resolved?" do
    link = Link.new
    link.should respond_to(:resolved?)
  end
  it "should respond to resolvable?" do
    link = Link.new
    link.should respond_to(:resolvable?)
  end
  it "by default, should not be resolvable" do
    link = Link.new
    link.should_not be_resolvable
  end
  it "by default, should not be resolved" do    
    link = Link.new
    link.should_not be_resolved
  end
  it "should not be valid if there is no href" do
    link = Link.new 'rel' => 'collection', 'title' => 'my collection'
    link.should_not be_valid
  end
  it "should not be valid if there is no rel" do
    link = Link.new 'href' => '/', 'title' => 'my collection'
    link.should_not be_valid
  end
  it "should not be valid if the rel is valid but requires a title that is not given" do
    link = Link.new 'rel' => 'collection', 'href' => '/'
    link.should_not be_valid
  end
end