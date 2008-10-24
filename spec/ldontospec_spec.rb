require 'lib/ldontospec'

describe LDOntoSpec do
  before(:each) do
    @base = LDOntoSpec::Base.new('test')
  end
  
  it "should create a new ldontospec" do
    @base.should_not be_nil
  end
end
