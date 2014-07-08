require 'spec_helper'

describe "The Runner" do
  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "ok\n"))
    @server = Screwcap::Server.new :name => :server,  :address => "fake.com", :user => "fake"
    @task = Screwcap::Task.new :name => :test, :server => :server do
      run "one"
      run "two"
    end
    @task.__build_commands
    @task.validate([@server])
  end

  it "should be able to execute commands on an address of a server" do
    Screwcap::Runner.stubs(:ssh_exec!).returns(["ok\n","",0,nil])

    commands = Screwcap::Runner.execute! :name => "test", 
      :servers => [@server],
      :task => @task, 
      :silent => true

    commands[0][:stderr].should == ""
    commands[0][:stdout].should == "ok\n"

    commands[1][:stderr].should == ""
    commands[1][:stdout].should == "ok\n"
  end

  it "should be able to handle error commands" do
    #Screwcap::Runner.stubs(:ssh_exec!).returns(["ok\n","",0,nil]).then.returns(["","no\n",1,nil])
    Screwcap::Runner.stubs(:ssh_exec!).returns(["","no\n",1,nil])
    commands = Screwcap::Runner.execute! :name => "test", 
      :servers => [@server], 
      :task => @task, 
      :silent => true

    commands[0][:stderr].should == "no\n"
    commands[0][:stdout].should == ""

    commands[1][:stderr].should == "no\n"
    commands[1][:stdout].should == ""
  end

  it "should be able to execute local commands" do
    task = Screwcap::Task.new :name => :localtest do
      local "echo 'bongle'"
    end
    task.__build_commands
    commands = Screwcap::Runner.execute! :name => :localtest, :task => task, :silent => true
    commands[0][:stdout].should == "bongle\n"
  end

  it "should be able to execute ex commands" do
    @@testvar = :bingo
    task = Screwcap::Task.new :name => :extest do
      ex { @@testvar = :bango }
    end
    task.__build_commands
    @@testvar.should == :bingo
    commands = Screwcap::Runner.execute! :name => "test", 
      :servers => [@server], 
      :task => task,
      :silent => true
    @@testvar.should == :bango
  end

  it "should yield a run block" do
    Screwcap::Runner.stubs(:ssh_exec!).returns(["ok\n","",0,nil]).then.returns(["","no\n",1,nil])
    revert_task = Screwcap::Task.new :name => :revert do
      run "revert" do |results|
        if results.exit_code != 0
          run "failed"
        else
          run "succeeded"
        end
      end
    end
    task = Screwcap::Task.new :name => :runblock, :server => :server do
      run "do_something" do |results|
        revert
      end
    end
    task.__build_commands
    task.validate([@server])
    commands = Screwcap::Runner.execute! :name => :runblock, :task => task, :tasks => [task, revert_task], :servers => [@server], :silent => true
    command_names(commands).should == %w(do_something revert failed)
  end

  it "should be able to run tasks parallel or serial" do
    @server2 = Screwcap::Server.new :name => :server2,  :address => "fake2.com", :user => "fake"
    Screwcap::Runner.stubs(:ssh_exec!).returns(["ok\n","",0,nil])
    task = Screwcap::Task.new :name => :parallel_task, :servers => [:server, :server2] do
      run "one"
      run "two"
    end
    task.__build_commands
    task.validate([@server, @server2])
    commands = Screwcap::Runner.execute! :name => :parallel_task, :task => task, :tasks => [task], :servers => [@server, @server2]
    command_names(commands).should == %w(one one two two)

    task = Screwcap::Task.new :name => :serial_task, :parallel => false, :servers => [:server, :server2] do
      run "one"
      run "two"
    end
    task.__build_commands
    task.validate([@server, @server2])
    commands = Screwcap::Runner.execute! :name => :serial_task, :task => task, :tasks => [task], :servers => [@server, @server2], :silent => true
    command_names(commands).should == %w(one two one two)
  end
end

def command_names(commands)
  ret = []
  commands.each do |command|
    if command.class == Hash
      ret << command[:command]
    elsif command.class == Array
      ret << command_names(command)
    end
  end
  ret.flatten
end
