require File.dirname(__FILE__) + '/test_helper.rb'

class TestDeployer < Test::Unit::TestCase

  def setup
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
  end

  def test_deployer_structure_and_assigning_variables
    deployer = Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true)
    assert deployer
    assert deployer.__options

    servers = deployer.__servers
    assert servers
    assert servers.first.addresses
    assert_equal ["slashdot.org","google.com"], servers.first.addresses

    assert_equal "tester", deployer.deploy_var
    assert_equal "bongo", deployer.deploy_var_2
    assert_equal %w(one two), deployer.deploy_var_3

    task = deployer.__tasks.find {|t| t.name == :task1}
    assert task

    # this tests overriding deployment vars here
    assert_equal "tester", task.deploy_var
    assert_equal "shasta", task.deploy_var_2
    assert_equal %w{one two}, task.deploy_var_3
    assert_equal ["deploy dir = tester", "command 2","command 3","tester","shasta", "bongo"], task.__commands

    task = deployer.__tasks.find {|t| t.name == :task2}
    assert task
    assert_equal "tester", task.deploy_var
    assert_equal "bongo", task.deploy_var_2
    assert_equal "mountain dew", task.deploy_var_3
    assert_equal [], task.__commands
  end

  def test_no_server
    assert_raise(ArgumentError) { Deployer.new(:recipe_file => "./test/config/no_server.rb", :silent => true) }
  end

  def test_undefined_item_in_task
    assert_raise(NoMethodError) { Deployer.new(:recipe_file => "./test/config/undefined_item.rb", :silent => true) }
  end


  def test_cannot_find_task
    #assert_raise(Screwcap::TaskNotFound) { Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => false).run! :task }
  end

end
