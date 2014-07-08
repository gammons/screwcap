require 'spec_helper'

describe "Servers" do
  before(:each) do
    @stdout = []
    @stderr = []
    Screwcap::Runner.stubs(:log).with() { |msg,opts| @stdout <<  msg }
    Screwcap::Runner.stubs(:errorlog).with() { |msg,opts| @stderr <<  msg }
    Net::SSH::Gateway.stubs(:new).returns(SSHObject.new)
  end

  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
  end

  it "should complain if you do not provide an address" do
    lambda { Screwcap::Server.new(:name => :test) }.should raise_error(Screwcap::InvalidServer)
  end

  it "should complain if you do not provide a username" do
    lambda { Screwcap::Server.new(:name => :test, :address => "abc.com") }.should raise_error(Screwcap::InvalidServer)
  end

  it "should complain if a gateway contains more than one address" do
    lambda { Screwcap::Server.new(:name => :test, :addresses => ["abc.com", "def.com"], :user => "root", :is_gateway => true) }.should raise_error(Screwcap::InvalidServer)
  end

  it "should provide a connection to the server" do
    server = Screwcap::Server.new(:name => :test, :user => :root, :address => "abc.com")
    server.should respond_to(:connect!)
  end
end
