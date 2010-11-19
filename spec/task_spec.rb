require 'spec_helper'

describe "Tasks" do
  it "should have a task-like structure" do
    task = Task.new :name => :test do
      run "test"
    end

    task.__commands.should have(0).__commands
    task.__build_commands
    task.__commands.should_not be_nil
    task.should have(1).__commands

    task.__commands[0][:type].should == :remote
    task.__commands[0][:from].should == :test
    task.__commands[0][:command].should == "test"
  end

  it "should be able to build commands" do
    unknown = Task.new :name => :unknown_action do
      run "unknown"
    end

    task = Task.new :name => :test do
      run "test"
      unknown_action
    end

    commands = task.__build_commands([unknown])
    commands.size.should == 2

    commands[0][:type].should == :remote
    commands[0][:from].should == :test
    commands[0][:command].should == "test"

    commands[1][:type].should == :remote
    commands[1][:from].should == :unknown_action
    commands[1][:command].should == "unknown"
  end

  it "should throw an error if we cannot find a command" do
    task = Task.new :name => :test do
      run "test"
      unknown_action
    end

    lambda {task.__build_commands([task])  }.should raise_error(NoMethodError)
  end

  it "should be able to create variables" do
    task = Task.new :name => :test do
      set :blaster, "stun"
      run "fire #{blaster}"
    end
    task.__build_commands
    task.blaster.should == "stun"
    task.__commands.first[:command].should == "fire stun"
  end

  it  "command sets should inherit the parent's variables" do
    subsub = Task.new :name => :subsubtask do
      set :from, "venus"
      run "fly to #{where} from #{from}"
    end

    sub = Task.new :name => :subtask do
      set :from, "mars"
      run "fly to #{where} from #{from}"
      subsubtask
    end

    task = Task.new :name => :task do
      set :where, "the moon"
      set :from, "earth"
      run "fly to #{where} from #{from}"
      subtask
    end

    commands = task.__build_commands([sub, subsub])
    commands[0][:from].should == :task
    commands[0][:command].should == "fly to the moon from earth"

    commands[1][:from].should == :subtask
    commands[1][:command].should == "fly to the moon from mars"

    commands[2][:from].should == :subsubtask
    commands[2][:command].should == "fly to the moon from venus"
  end

  it "should respond to :before or before_ calls" do
    before = Task.new :name => :do_before do
      run "before"
    end
    task = Task.new :name => :test, :before => :do_before do
      run "task"
    end

    before2 = Task.new :name => :before_deploy do
      run "before"
    end

    task2 = Task.new :name => :deploy do
      run "deploy"
    end

    commands = task.__build_commands([before])
    commands.map {|c| c[:command] }.should == ["before","task"]

    commands = task2.__build_commands([before2])
    commands.map {|c| c[:command] }.should == ["before","deploy"]
  end

  it "should respond to :after or after_ calls" do
    after = Task.new :name => :do_after do
      run "after"
    end
    task = Task.new :name => :test, :after => :do_after do
      run "task"
    end

    after2 = Task.new :name => :after_deploy do
      run "after"
    end

    task2 = Task.new :name => :deploy do
      run "deploy"
    end

    commands = task.__build_commands([after])
    commands.map {|c| c[:command] }.should == ["task","after"]

    commands = task2.__build_commands([after2])
    commands.map {|c| c[:command] }.should == ["deploy", "after"]
  end

  it "should validate" do
    task = Task.new :name => :test 
    lambda { task.validate([]) }.should raise_error(Screwcap::ConfigurationError)

    server = Server.new :name => :server, :address => "none", :user => "yeah"
    other_server = Server.new :name => :server2, :address => "none", :user => "yeah"
    task = Task.new :name => :test, :server => :server
    lambda { task.validate([server]) }.should_not raise_error
    lambda { task.validate([other_server]) }.should raise_error(Screwcap::ConfigurationError)
    task = Task.new :name => :test, :servers => :server
    lambda { task.validate([server]) }.should_not raise_error
    task = Task.new :name => :test, :servers => [:server, :server2]
    lambda { task.validate([server,other_server]) }.should_not raise_error
  end

  it "should handle before and after inside a task" do
    do_other_task = Task.new :name => :other_task do
      run "task"
    end
    task = Task.new :name => :task do
      before :other_task do
        run "before"
      end
      after :other_task do
        run "after"
      end

      other_task
    end

    commands = task.__build_commands([do_other_task])
    commands.map {|c| c[:command] }.should == %w(before task after)
  end

  it "before and after call blocks can call command sets just like everything else" do
    special = Task.new :name => :run_special_command do
      run "special"
    end
    other = Task.new :name => :other_task do
      run "other"
    end

    task = Task.new :name => :task do
      before :other_task do
        run_special_command
      end
      after :other_task do
        run "after"
      end
      other_task
    end
    commands = task.__build_commands([special, other])
    commands.map {|c| c[:command] }.should == %w(special other after)
  end

  it "should be able to handle multiple befores inside" do
    special = Task.new :name => :run_special_command do
      run "special"
    end
    other = Task.new :name => :other_task do
      run "other"
    end

    task = Task.new :name => :task do
      before :other_task do
        run_special_command
      end
      before :other_task do
        run "moon_pie"
      end
      after :other_task do
        run "after"
      end
      other_task
    end
    commands = task.__build_commands([special, other])
    commands.map {|c| c[:command] }.should == %w(special moon_pie other after)
  end

  it "should be able to handle multiple befores outside" do
    before1 = Task.new :name => :do1 do
      run "do1"
    end

    before2 = Task.new :name => :do2 do
      run "do2"
    end

    task = Task.new :name => :new_task, :before => [:do1, :do2] do
      run "task"
    end

    commands = task.__build_commands([before1, before2])
    commands.map {|c| c[:command] }.should == %w(do1 do2 task)
  end
end
