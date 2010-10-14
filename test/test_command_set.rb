require File.dirname(__FILE__) + '/test_helper.rb'

class TestDeployer < Test::Unit::TestCase

  def setup
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
  end

  def test_command_sets
    deployer = Deployer.new(:recipe_file => "./test/config/command_sets.rb", :silent => true)
    assert deployer

    task = deployer.__tasks.find {|t| t.name == :use_command_set_no_override }
    assert task

    task.__command_sets.first.instance_eval(&task.__command_sets.first.__block)
    assert_equal ["tester","run with tester", "bongo"], task.__commands

    task = deployer.__tasks.find {|t| t.name == :use_command_set_with_override }
    assert task

    assert_equal ["shasta","run with shasta", "bongo"], task.__commands

    task = deployer.__tasks.find {|t| t.name == :use_command_set_complex_override }
    assert task
    assert_equal ["dingle"], task.__commands
  end

  def test_nested_command_sets
    deployer = Deployer.new(:recipe_file => "./test/config/command_sets.rb", :silent => true)

    task = deployer.__tasks.find {|t| t.name == :nested_command_set }
    assert task
    assert_equal %w(1 2 3 4), task.__commands
  end

  def test_undefined_value_in_command_set
    assert_raise(NoMethodError) { Deployer.new(:recipe_file => "./test/config/undefined_command_set.rb", :silent => true) }
  end
end
