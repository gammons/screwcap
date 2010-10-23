require 'spec_helper'

describe "Deployers" do
  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
  end

  it "should complain if no server was defined" do
    lambda { Deployer.new(:recipe_file => "./test/config/no_server.rb", :silent => true)}.should raise_error(Screwcap::ConfigurationError)
  end

  it "should complain if there is an undefined item in a task" do
    lambda { Deployer.new(:recipe_file => "./test/config/undefined_item.rb", :silent => true)}.should raise_error(NoMethodError)
  end

  it "should complain if screwcap cannot find the task to run" do
    lambda { Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true).run! :task }.should raise_error(Screwcap::TaskNotFound)
  end

  it "should complain if a gateway has more than one address" do
  end

  it "should be able to define tasks and servers" do
    deployer = Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true)

    deployer.should have(6).__tasks
    deployer.should have(2).__servers
  end

  it "should be able to define variables with set" do
    deployer = Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true)
    deployer.should respond_to(:deploy_var)
    deployer.should respond_to(:deploy_var_2)
    deployer.should respond_to(:deploy_var_3)

    deployer.deploy_var.should == "tester" 
    deployer.deploy_var_2.should == "bongo"
    deployer.deploy_var_3.should == ["one","two"]
  end

  it "should be able to define command sets" do
    deployer = Deployer.new(:recipe_file => "./test/config/command_sets.rb", :silent => true)
    deployer.should have(9).__command_sets
  end

  it "should be able to define gateways" do
    deployer = Deployer.new(:recipe_file => "./test/config/gateway.rb", :silent => true)
    deployer.should have(3).__servers
    deployer.__servers.select {|s| s.__options[:is_gateway] == true }.size.should == 1
  end

  it "should be able to define sequences" do
    deployer = Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true)
    deployer.should have(1).__sequences
  end

  it "should be able to run a single task" do
    deployer = Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true)
    lambda { deployer.run! :task1 }.should_not raise_error
  end

  it "should be able to run multiple tasks" do
    deployer = Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true)
    lambda { deployer.run! :task1, :task2 }.should_not raise_error
  end

  it "should be able to include other task files with the use keyword" do
    deployer = Deployer.new(:recipe_file => "./test/config/use.rb", :silent => true)
    deployer.should have(6).__tasks
    deployer.deploy_var.should == "tester"
  end

  it "should complain if we attempt to use an unknown file" do
    lambda {Deployer.new(:recipe_file => "./test/config/unknown_use.rb", :silent => true) }.should raise_error(Screwcap::IncludeFileNotFound)
  end
end
