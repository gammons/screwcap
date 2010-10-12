require File.dirname(__FILE__) + '/test_helper.rb'

class TestScrewcap < Test::Unit::TestCase
  class SSHObject
    attr_accessor :options

    def initialize(options)
      @options = {:return_stream => :stdout}
      @options = options
    end

    def exec!(cmd, &block)
      yield nil, @options[:return_stream], @options[:return_data]
    end
  end

  def setup
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
  end

  def test_basics
    assert_raise(Errno::ENOENT) { Deployer.new(:blah, :task_file => "__noexist") }
    assert_raise(Screwcap::TaskNotFound) { Deployer.new("__noexist", :task_file => "./test/config/simple_recipe.rb" ).run! }
  end

  def test_overriding_params
    # the first recipe does not override global params.
    deployer = Deployer.new(:no_override, :task_file => "./test/config/simple_recipe.rb", :silent => true)
    deployer.run!

    assert_equal({:run0 => ["hostname"]}, deployer.active_recipe.commands)

    # now ensure that the global settings are indeed imparted on this particular recipe
    assert_equal deployer.active_recipe.deploy, deployer.deploy
    assert_equal deployer.active_recipe.svn, deployer.svn
    assert_equal deployer.active_recipe.server_urls, deployer.server_urls

    # the 2nd recipe overrides global params.
    deployer = Deployer.new("override", :task_file => "/test/config/simple_recipe.rb", :silent => true)

    assert_not_equal deployer.active_recipe.deploy_dir, deployer.deploy_dir
    assert_not_equal deployer.active_recipe.svn, deployer.svn
  end

  def test_successful_command
    deployer = Deployer.new("success", :task_file => "/test/config/single_recipe.rb", :silent => true)
    deployer.run!
    assert deployer.active_recipe.command_order.all? {|c| c[:status] == :success }
  end

  def test_stderr
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stderr, :return_data => "hostname = asdf\n"))
    deployer = Deployer.new("success", :task_file => "/test/config/single_recipe.rb", :silent => true)
    assert deployer
    deployer.run!
    assert deployer.active_recipe.command_order.all? {|c| c[:status] == :error }
  end

  def test_stop_on_errors
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stderr, :return_data => "hostname = asdf\n"))

    deployer = Deployer.new("stop_on_errors", :task_file => "/test/config/single_recipe.rb", :silent => true)
    deployer.run!
    assert deployer.active_recipe.command_order.first[:status] == :error
    assert deployer.active_recipe.command_order.last[:status].nil? 
  end

  def test_command_set
    deployer = Deployer.new("test_command_sets", :task_file => "/test/config/command_set.rb", :silent => true)
    assert deployer
    assert deployer.active_recipe.command_order.all? {|c| c[:status] == :success }
  end

  def test_command_set_can_set_vars
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "success\n"))
    deployer = Deployer.new("run_check_out", :task_file => "/test/config/command_set.rb", :silent => true)
    assert deployer

    cs = deployer.command_sets.select {|cs| cs.name == :svn_check_out }.first

    # we overrode the original apache dir 
    assert_equal "overridden", cs.apache[:dir]
    assert_equal "/home/deploy", cs.deploy[:dir]
    assert_equal "http://blah2", cs.svn[:url]

    # NOW assert the server is different.


    assert_equal true, deployer.active_recipe.command_order.all? {|c| c[:status] == :success }
  end

  #def test_command_set_failed_deps
  #  Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "success"))

  #  assert_raises Screwcap::CommandSetDependencyError do
  #    deployer = Deployer.new("unmet_dep", :task_file => "/test/config/command_set_dependent_dep.rb")
  #  end
  #end

  #def test_command_set_met_deps
  #  Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "success"))
  #  deployer = Deployer.new("all_met_deps", :task_file => "/test/config/command_set.rb")
  #  assert deployer

  #  assert_equal true, deployer.active_recipe.command_order.all? {|c| c[:status] == :success }
  #end

  def test_callbacks
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "success\n"))
    deployer = Deployer.new("something", :task_file => "/test/config/callbacks.rb", :silent => true)
    deployer.run!
    assert deployer.active_recipe.command_order.all? {|c| c[:status] == :success }
    assert deployer.options[:before_method]
    assert deployer.options[:before_method_2]
    assert deployer.options[:after_method]
  end

  def test_extra_params
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "success\n"))
    deployer = Deployer.new("something", :task_file => "/test/config/callbacks.rb", :params => ["extra_param1","extra_param2"], :silent => true)
    assert deployer

    assert_equal ["extra_param1","extra_param2"], deployer.params
    assert_equal ["extra_param1","extra_param2"], deployer.active_recipe.params
  end

  # command sets are included in the deployment by default, but in order for them to 
  # have the correct vars, we'll need to include them again into each task.
  def test_command_set_is_reincluded_in_tasks
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "success\n"))
    deployer = Deployer.new("redefine_var", :task_file => "/test/config/included_command_set.rb", :silent => true)
    assert deployer
    assert_equal "ls -l 2", deployer.active_recipe.command_order.first[:input]

    deployer = Deployer.new("keep_var", :task_file => "/test/config/included_command_set.rb", :silent => true)
    assert deployer
    assert_equal "ls -l 1", deployer.active_recipe.command_order.first[:input]

    deployer = Deployer.new("redefine_var_again", :task_file => "/test/config/included_command_set.rb", :silent => true)
    assert deployer
    assert_equal "ls -l blargin", deployer.active_recipe.command_order.first[:input]
  end

  def test_command_set_reinclude_hash
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "success\n"))
    deployer = Deployer.new("redefine_hash", :task_file => "/test/config/included_command_set.rb", :silent => true)
    assert deployer
    assert_equal "hashval is blargo", deployer.active_recipe.command_order.first[:input]

    deployer = Deployer.new("do_not_redefine_hash", :task_file => "/test/config/included_command_set.rb", :silent => true)
    assert deployer
    assert_equal "hashval is margin", deployer.active_recipe.command_order.first[:input]
  end

  def test_command_set_with_undefined_var
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "success\n"))
    deployer = Deployer.new(:undefined_var, :task_file => "/test/config/included_command_set.rb", :silent => true)
    deployer.run!
  end

  def test_command_set_reinclude_multiple
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "success\n"))

    deployer = Deployer.new("redefine_one_not_other", :task_file => "/test/config/included_command_set.rb", :silent => true)
    deployer.run!
    assert_equal "thing is 2, another thing is margin", deployer.active_recipe.command_order.first[:input]

    deployer = Deployer.new("redefine_both", :task_file => "/test/config/included_command_set.rb")
    deployer.run!
    assert_equal "thing is 5, another thing is mango", deployer.active_recipe.command_order.first[:input]

    deployer = Deployer.new("redefine_one_not_other_2", :task_file => "/test/config/included_command_set.rb")
    deployer.run!
    assert_equal "thing is 1, another thing is mango", deployer.active_recipe.command_order.first[:input]
  end

  def test_server_command
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "success\n"))
    deployer = Deployer.new("use_server", :task_file => "/test/config/server.rb", :silent => true)
    assert deployer
    assert deployer.active_recipe.options[:deploy][:dir]
    assert_equal "/mnt/app", deployer.active_recipe.options[:deploy][:dir]
    assert_equal "/mnt/app/shared/pids", deployer.active_recipe.options[:mongrel][:pid_dir]

    # test overriding server params inside the task.
    assert_equal "something_else", deployer.active_recipe.options[:release][:dir]
  end
end
