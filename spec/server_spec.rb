require 'spec_helper'

describe "Servers" do
  before(:each) do
    @stdout = []
    @stderr = []
    Task.any_instance.stubs(:log).with() { |msg| @stdout <<  msg }
    Task.any_instance.stubs(:errorlog).with() { |msg| @stderr <<  msg }
    Deployer.any_instance.stubs(:log).with() { |msg| @stdout <<  msg }
    Deployer.any_instance.stubs(:errorlog).with() { |msg| @stderr <<  msg }

    Net::SSH::Gateway.stubs(:new).returns(SSHObject.new)
  end

  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
  end

  it "should complain if you do not provide an address" do
    lambda { Server.new(:name => :test) }.should raise_error(Screwcap::InvalidServer)
  end

  it "should complain if you do not provide a username" do
    lambda { Server.new(:name => :test, :address => "abc.com") }.should raise_error(Screwcap::InvalidServer)
  end

  it "should complain if a gateway contains more than one address" do
    lambda { Server.new(:name => :test, :addresses => ["abc.com", "def.com"], :user => "root", :is_gateway => true) }.should raise_error(Screwcap::InvalidServer)
  end

  it "should provide a connection to the server" do
    server = Server.new(:name => :test, :user => :root, :address => "abc.com")
    server.should respond_to(:__with_connection_for)
  end

  it "should provide a connection to the server with a gateway" do
    @deployer = Deployer.new(:recipe_file => "./test/config/gateway.rb", :silent => false)
    server = @deployer.__servers.find {|s| s.__name == :test}
    gateway = @deployer.__servers.find {|s| s.__name == :gateway1}

    output = []
    lambda { server.__with_connection {} }.should_not raise_error 
  end
end
