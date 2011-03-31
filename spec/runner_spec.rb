require 'spec_helper'

describe "The Runner" do
  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "ok\n"))
    @server = Server.new :name => :server,  :address => "fake.com", :user => "fake"
    @task = Task.new :name => :test, :server => :server do
      run "one"
      run "two"
    end
    @task.__build_commands
    @task.validate([@server])
  end

  it "should be able to execute commands on an address of a server" do
    Runner.stubs(:ssh_exec!).returns(["ok\n","",0,nil])

    commands = Runner.execute! :name => "test", 
      :servers => [@server],
      :task => @task, 
      :silent => true

    commands[0][:stderr].should == ""
    commands[0][:stdout].should == "ok\n"

    commands[1][:stderr].should == ""
    commands[1][:stdout].should == "ok\n"
  end

  it "should be able to handle error commands" do
    #Runner.stubs(:ssh_exec!).returns(["ok\n","",0,nil]).then.returns(["","no\n",1,nil])
    Runner.stubs(:ssh_exec!).returns(["","no\n",1,nil])
    commands = Runner.execute! :name => "test", 
      :servers => [@server], 
      :task => @task, 
      :silent => true

    commands[0][:stderr].should == "no\n"
    commands[0][:stdout].should == ""

    commands[1][:stderr].should == "no\n"
    commands[1][:stdout].should == ""
  end

  it "should be able to execute local commands" do
    task = Task.new :name => :localtest do
      local "echo 'bongle'"
    end
    task.__build_commands
    commands = Runner.execute! :name => :localtest, :task => task, :silent => true
    commands[0][:stdout].should == "bongle\n"
  end

  it "should be able to execute ex commands" do
    @@testvar = :bingo
    task = Task.new :name => :extest do
      ex { @@testvar = :bango }
    end
    task.__build_commands
    @@testvar.should == :bingo
    commands = Runner.execute! :name => "test", 
      :servers => [@server], 
      :task => task,
      :silent => true
    @@testvar.should == :bango
  end

  it "should yield a block from run" do
    @server = Server.new :name => :server,  :address => "fake.com", :user => "fake"
    task = Task.new :name => :dingle, :server => :server do
      run "ls -l" do |command|
        command.should == {:type=>:remote, :stdout=>"", :command=>"ls -l", :stderr=>"no\n", :exit_code=>1, :from=>:dingle}
      end
    end
    task.validate([@server])
    task.__build_commands
    commands = Runner.execute! :name => "dingle", 
      :servers => [@server], 
      :task => task, 
      :silent => true
  end
end
