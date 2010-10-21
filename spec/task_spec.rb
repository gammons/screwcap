require 'spec_helper'

describe "Tasks" do
  before(:each) do
    @stdout = []
    @stderr = []
    Task.any_instance.stubs(:log).with() { |msg| @stdout <<  msg }
    Task.any_instance.stubs(:errorlog).with() { |msg| @stderr <<  msg }
    Deployer.any_instance.stubs(:log).with() { |msg| @stdout <<  msg }
    Deployer.any_instance.stubs(:errorlog).with() { |msg| @stderr <<  msg }
    @deployer = Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => false)
  end

  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
  end

  it "should be able to create variables" do
    task = @deployer.__tasks.find {|t| t.name == :task1 }
    task.bango.should == "bongo"
  end

  it "should compile run statements" do
    task = @deployer.__tasks.find {|t| t.name == :task1 }
    task.should have(6).__commands
  end

  it "should be able to execute statements on a remote server" do
    task = @deployer.__tasks.find {|t| t.name == :task1 }
    task.execute!
    @stderr.should == []
    @stdout.size.should == 29
  end

  it "should be able to use variables in the run statement" do
    task = @deployer.__tasks.find {|t| t.name == :task1 }
    command = task.__commands.map{|c| c[:command] }.find {|c| c.index "deploy dir" }
    command.should == "deploy dir = tester"
  end

  it "should be able to override a globally set variable" do
    @deployer.deploy_var_2.should == "bongo"
    @deployer.deploy_var_3.should == %w(one two)

    task = @deployer.__tasks.find {|t| t.name == :task1 }
    task.deploy_var_2.should == "shasta"

    task = @deployer.__tasks.find {|t| t.name == :task2 }
    task.deploy_var_2.should == "purple"
    task.deploy_var_3.should == "mountain dew"
  end

  it "should complain if you do not pass the task a server argument" do
    lambda { Deployer.new(:recipe_file => "./test/config/no_server.rb", :silent => false)}.should raise_error(Screwcap::ConfigurationError)
  end

  it "should complain if you pass a server that is not defined" do
    lambda { Deployer.new(:recipe_file => "./test/config/undefined_server.rb", :silent => false)}.should raise_error(Screwcap::ConfigurationError)
  end

  it "should be able to disable parallel running" do
    # this is hard to test.  with threads and stuff
    lambda { @deployer.run! :non_parallel }.should_not raise_error
  end

  it "should be able to run local commands" do 
    lambda { @deployer.run! :task3 }.should_not raise_error
  end
end
