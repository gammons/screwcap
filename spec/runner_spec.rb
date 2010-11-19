require 'spec_helper'

describe "The Runner" do
  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "ok\n"))
    @server = Server.new :name => :server,  :address => "fake.com", :user => "fake"
    @task = Task.new :name => :test, :server => :server do
      run "one"
      run "two"
    end
  end

  it "should be able to execute commands on an address of a server" do
    Runner.stubs(:ssh_exec!).returns(["ok\n","",0,nil])

    commands = Runner.execute! :name => "test", 
      :server => @server, 
      :address => "fake.com", 
      :commands => @task.__build_commands, 
      :silent => true

    commands[0][:stderr].should == ""
    commands[0][:stdout].should == "ok\n"

    commands[1][:stderr].should == ""
    commands[1][:stdout].should == "ok\n"
  end

  it "should be able to handle error commands" do
    Runner.stubs(:ssh_exec!).returns(["ok\n","",0,nil]).then.returns(["","no\n",1,nil])
    commands = Runner.execute! :name => "test", 
      :server => @server, 
      :address => "fake.com", 
      :commands => @task.__build_commands, 
      :silent => true

    commands[0][:stderr].should == ""
    commands[0][:stdout].should == "ok\n"

    commands[1][:stderr].should == "no\n"
    commands[1][:stdout].should == ""
  end

  it "should be able to execute local commands" do
    task = Task.new :name => :localtest, :local => true do
      run "echo 'bongle'"
    end
    commands = Runner.execute_locally! :name => :localtest, :commands => task.__build_commands, :silent => true
    commands[0][:stdout].should == "bongle\n"
  end
end
