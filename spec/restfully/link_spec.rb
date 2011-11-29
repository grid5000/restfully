require 'spec_helper'

describe Restfully::Link do
  before do
    @uri = URI.parse('/x/y/z')
    @valid_attributes = {
      :rel => 'something',
      :type => 'application/json',
      :href => '/'
    }
  end

  describe "accessors" do
    it "should have a rel reader" do
      link = Restfully::Link.new
      link.should_not respond_to(:rel=)
      link.should respond_to(:rel)
    end
    it "should have a href reader" do
      link = Restfully::Link.new
      link.should_not respond_to(:href=)
      link.should respond_to(:href)
    end
    it "should have a title reader" do
      link = Restfully::Link.new
      link.should_not respond_to(:title=)
      link.should respond_to(:title)
    end
    it "should have a errors reader" do
      link = Restfully::Link.new
      link.should_not respond_to(:errors=)
      link.should respond_to(:errors)
    end
    it "should respond to valid?" do
      link = Restfully::Link.new
      link.should respond_to(:valid?)
    end
  end

  describe "validations" do
    before do
      @media_type = mock(Restfully::MediaType::AbstractMediaType)
    end
    
    it "should be valid even if there is no type" do
      link = Restfully::Link.new(@valid_attributes.merge(:type => nil))
      link.should be_valid
      link.types.should == []
    end
    
    it "should be valid even if a media_type cannot be found" do
      Restfully::MediaType.catalog.clear
      link = Restfully::Link.new(@valid_attributes)
      link.should be_valid
    end
    

    describe "with a valid catalog" do
      before do
        Restfully::MediaType.stub!(:find).and_return(@media_type)
      end

      it "should be valid" do
        link = Restfully::Link.new(@valid_attributes)
        link.should be_valid
      end

      it "should be valid even if the href is ''" do
        link = Restfully::Link.new(@valid_attributes.merge(:href => ''))
        link.should be_valid
        link.href.should == URI.parse("")
      end
    end


  end


end