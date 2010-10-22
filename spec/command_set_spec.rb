require 'spec_helper'

describe "Command sets" do
  before(:all) do
    @stdout = []
    Deployer.any_instance.stubs(:log).with() { |msg| @stdout << msg}
    @deployer = Deployer.new(:recipe_file => "./test/config/command_sets.rb", :silent => false)
  end

  it "should be able to define a generic list of commands" do
    task = @deployer.__tasks.find {|t| t.__name == :really_simple_task }
    task.should have(3).__commands
    task.__commands.map{|c| c[:command]}.should == %w(1 2 3)
  end

  it "should be able to use deployment variables" do
    task = @deployer.__tasks.find {|t| t.__name == :use_command_set_no_override }
    task.__command_sets.first.instance_eval(&task.__command_sets.first.__block)
    task.__commands.map {|c| c[:command]}.should == ["tester","run with tester","bongo"]
  end

  it "should be able to use task variables" do
    task = @deployer.__tasks.find {|t| t.__name == :task_set_var }
    task.__command_sets.first.instance_eval(&task.__command_sets.first.__block)
    task.__commands.map {|c| c[:command]}.should == ["bojangles"]
  end

  it "should favor variables that were overridden by a task" do
    task = @deployer.__tasks.find {|t| t.__name == :use_command_set_with_override }
    task.__command_sets.first.instance_eval(&task.__command_sets.first.__block)
    task.__commands.map {|c| c[:command]}.should == ["shasta","run with shasta","bongo"]
  end

  it "should favor variables defined in the command set definition" do
    task = @deployer.__tasks.find {|t| t.__name == :command_set_override }
    task.__command_sets.first.instance_eval(&task.__command_sets.first.__block)
    task.__commands.map {|c| c[:command]}.should == ["dingle"]
  end

  it "should accept nested command sets" do
    task = @deployer.__tasks.find {|t| t.__name == :nested_command_set }
    task.__command_sets.first.instance_eval(&task.__command_sets.first.__block)
    task.__commands.map {|c| c[:command]}.should == %w(1 2 3 4)
  end

  it "nested command sets have their own variable scope" do
    task = @deployer.__tasks.find {|t| t.__name == :nested_scoping }
    task.__command_sets.first.instance_eval(&task.__command_sets.first.__block)
    task.__commands.map {|c| c[:command]}.should == %w(birdo nested birdo task)
  end

  it "should be able to call scp just like a task" do
    task = @deployer.__tasks.find {|t| t.__name == :task_use_scp}
    task.__command_sets.first.instance_eval(&task.__command_sets.first.__block)
    task.__commands.map {|c| c[:command]}.should == [nil]
  end
end
