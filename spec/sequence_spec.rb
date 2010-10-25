require 'spec_helper'

describe "Sequences" do
  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
    Runner.stubs(:ssh_exec!).returns(["ok","",0,nil])
  end
  before(:each) do
    @stdout = []
    Deployer.any_instance.stubs(:log).with() { |msg| @stdout << msg}
    @deployer = Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true)
  end

  it "should contain a list of tasks to be called" do
    sequence = @deployer.__sequences.find {|s| s.__name == :deploy}
    sequence.__task_names.should == [:seq1, :seq2]
  end

  it "should be callable via Deployer.run!" do
    lambda { @deployer.run! :deploy }.should_not raise_error
  end
end
