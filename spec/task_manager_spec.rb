require 'spec_helper'

describe "Task Managers" do
  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "ok\n"))
    Runner.stubs(:ssh_exec!).returns(["ok\n","",0,nil])
  end

  before(:each) do
    @tm = TaskManager.new :silent => true
  end

  it "can have tasks and servers" do
    @tm.server :server, :address => "test", :user => "root"
    @tm.task :deploy, :server => :server do
      run "test"
    end

    @tm.should have(1).__servers
    @tm.should have(1).__tasks
  end

  it "should be able to define variables" do
    @tm.moon_pie= "moon pie"
    @tm.moon_pie.should == "moon pie"
  end

  it "should pass variables to tasks" do
    @tm.pie_type = "moon pie"
    @tm.server :server, :address => "test", :user => "root"
    @tm.task :deploy, :server => :server do
      run "#{pie_type} in the face!"
    end

    @tm.__tasks[0].__build_commands[0][:command].should == "moon pie in the face!"
  end

  it "should be able to define command sets" do
    @tm.command_set :my_command_set do
      run "test"
    end
    
    @tm.should have(1).__tasks
  end

  it "should be able to load a recipe file" do
    @tm = TaskManager.new(:recipe_file => "test/config/super_simple_recipe.rb")
    @tm.pie.should == "moon pie"
    @tm.should have(2).__tasks
  end

  it "should be able to execute a recipe" do
    @tm.pie_type = "moon pie"
    @tm.server :server, :address => "test", :user => "root"
    @tm.task :deploy, :server => :server do
      run "#{pie_type} in the face!"
    end
    commands = @tm.run! :deploy, :deploy2
    commands.size.should == 1
    commands.first[:command].should == "moon pie in the face!"
  end

  it "should be able to include multiple recipe files in a single recipe" do
    @tm = TaskManager.new(:recipe_file => "test/config/use.rb")
    @tm.pie.should == "moon pie"
    @tm.should have(2).__tasks

    @tm = TaskManager.new(:recipe_file => "test/config/use2.rb")
    @tm.pie.should == "moon pie"
    @tm.should have(2).__tasks
  end

  it "will complain if it can't find the use file" do
    lambda { TaskManager.new(:recipe_file => "test/config/bad_use.rb") }.should raise_error(Screwcap::IncludeFileNotFound)
  end

  it "should be able to define gateways" do
    @tm.gateway :gateway, :address => "xyz.com", :user => "root"
  end

  it "should be able to define and run sequences" do
    @tm.server :server, :address => "test", :user => "root"
    @tm.task(:task1, :server => :server) { run "task1" }
    @tm.task(:task2, :server => :server) { run "task2" }
    @tm.sequence :seq, :tasks => [:task1, :task2]
    commands = @tm.run! :seq
    commands.size.should == 2
    commands[0][:command].should == "task1"
    commands[1][:command].should == "task2"
  end

  it "command sets should retain global variables" do
    @tm.animal = "monkey"
    @tm.animal.should == "monkey"
    @tm.server :server, :address => "test", :user => "root"
    @tm.command_set(:pet_animal)  { run "pet #{animal}" }

    @tm.task(:pet_donkey, :server => :server) do
      set :animal, "donkey"
      pet_animal
    end
    @tm.task(:pet_global, :server => :server) do
      pet_animal
    end

    @tm.run!([:pet_donkey, :pet_global]).map {|c| c[:command] }.should == ["pet donkey","pet monkey"]
  end

  it "should not run callback command sets twice" do
    @tm.animal = "monkey"
    @tm.server :server, :address => "test", :user => "root"
    @tm.command_set(:pet_animal)  { run "pet_#{animal}" }
    @tm.command_set(:before_pet_animal) { run "prepare_hand" }

    @tm.task(:pet, :server => :server) do
      before :pet_animal do
        run "put_glove_on_hand"
      end
      pet_animal
    end

    @tm.run!(:pet).map {|c| c[:command] }.should == %w(put_glove_on_hand prepare_hand pet_monkey)
  end
end
