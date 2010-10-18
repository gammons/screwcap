require 'spec_helper'


describe "Deployer Exceptions" do
  it "should complain if no server was defined" do
    lambda { Deployer.new(:recipe_file => "./test/config/no_server.rb", :silent => true)}.should raise_error(Screwcap::ConfigurationError)
  end

  it "should complain if there is an undefined item in a task" do
    lambda { Deployer.new(:recipe_file => "./test/config/undefined_item.rb", :silent => true)}.should raise_error(NoMethodError)
  end

  it "should complain if screwcap cannot find the task to run" do
    lambda { Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true).run! :task }.should raise_error(Screwcap::TaskNotFound)
  end
end

describe "Deployer Functionality" do

  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
  end

  it "should be able to run a simple recipe" do
    deployer = Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true)
    lambda { deployer.run! :task1 }.should_not raise_error
  end
end
