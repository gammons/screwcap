require File.dirname(__FILE__) + '/test_helper.rb'

class TestServer < Test::Unit::TestCase

  def setup
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
  end

  def test_server
    assert_raise(Screwcap::InvalidServer) { Server.new(:name => :test) }
    assert_raise(Screwcap::InvalidServer) { Server.new(:name => :test, :address => "abc.com") }
    assert_raise(Screwcap::InvalidServer) { Server.new(:name => :test, :user => "root") }
    assert_nothing_raised { Server.new(:name => :test, :user => :root, :address => "abc.com") }
  end

end
