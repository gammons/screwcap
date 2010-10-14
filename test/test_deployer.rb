require File.dirname(__FILE__) + '/test_helper.rb'

class TestDeployer < Test::Unit::TestCase

  def setup
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
  end

  def test_deployer_structure
    deployer = Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true)
    assert deployer
    assert deployer.options

    servers = deployer.options[:servers]
    assert servers
    assert servers.first.addresses
    assert_equal ["slashdot.org","google.com"], servers.first.addresses
  end

  def test_cannot_find_task
    assert_raise(Screwcap::TaskNotFound) { Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => false).run! :task }
  end

end
