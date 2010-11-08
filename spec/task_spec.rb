require 'spec_helper'

describe "Tasks" do
  before(:each) do
    @stdout = []
    @stderr = []
    Runner.stubs(:log).with() { |msg,opts| @stdout <<  msg }
    Runner.stubs(:errorlog).with() { |msg,opts| @stderr <<  msg }
    @deployer = Deployer.new(:recipe_file => "./test/config/simple_recipe.rb", :silent => true)
  end

  before(:all) do
    Net::SSH.stubs(:start).yields(SSHObject.new(:return_stream => :stdout, :return_data => "hostname = asdf\n"))
    Net::SCP.stubs(:upload!).returns(nil)
    Runner.stubs(:ssh_exec!).returns(["ok","",0,nil])
  end

  it "should be able to create variables" do
    task = @deployer.__tasks.find {|t| t.name == :task1 }
    task.bango.should == "bongo"
  end

  it "should compile run statements" do
    task = @deployer.__tasks.find {|t| t.name == :task1 }
    task.should have(6).__commands
  end

  it "should be able to execute statements on a remote server" do
    task = @deployer.__tasks.find {|t| t.name == :task1 }
    Runner.execute! task, @deployer.__options
    @stderr.size.should == 0
    @stdout.size.should == 28
  end

  it "should be able to use variables in the run statement" do
    task = @deployer.__tasks.find {|t| t.name == :task1 }
    command = task.__commands.map{|c| c[:command] }.find {|c| c.index "deploy dir" }
    command.should == "deploy dir = tester"
  end

  it "should be able to override a globally set variable" do
    @deployer.deploy_var_2.should == "bongo"
    @deployer.deploy_var_3.should == %w(one two)

    task = @deployer.__tasks.find {|t| t.name == :task1 }
    task.deploy_var_2.should == "shasta"

    task = @deployer.__tasks.find {|t| t.name == :task2 }
    task.deploy_var_2.should == "purple"
    task.deploy_var_3.should == "mountain dew"
  end

  it "should complain if you do not pass the task a server argument" do
    lambda { Deployer.new(:recipe_file => "./test/config/no_server.rb", :silent => true)}.should raise_error(Screwcap::ConfigurationError)
  end

  it "should complain if you pass a server that is not defined" do
    lambda { Deployer.new(:recipe_file => "./test/config/undefined_server.rb", :silent => true)}.should raise_error(Screwcap::ConfigurationError)
  end

  it "should be able to disable parallel running" do
    # this is hard to test.  with threads and stuff
    lambda { @deployer.run! :non_parallel }.should_not raise_error
  end

  it "should be able to run local commands" do 
    lambda { @deployer.run! :task3 }.should_not raise_error
  end

  it "should be able to upload files using the scp command" do
    deployer = Deployer.new(:recipe_file => "./test/config/upload.rb", :silent => true)
    deployer.run! :upload
  end

  it "should respond to onfailure" do
    deployer = Deployer.new(:recipe_file => "./test/config/expect.rb", :silent => true)
    t = deployer.__tasks.find {|t| t.__name == :expect }
    Runner.stubs(:ssh_exec!).returns(["","fail",1,nil]).then.returns(["ok","",0,nil])
    Runner.execute! t, deployer.__options
    @stdout[1].should == "    I: (abc.com):  this will fail\n"
    @stderr[0].should == "    O: (abc.com):  fail"
    @stdout[2].should == "    I: (abc.com):  echo 'we failed'\n"
    @stdout[3].should == "    O: (abc.com):  ok"
    @stdout[4].should == "    I: (abc.com):  ls\n"
    @stdout[5].should == "    O: (abc.com):  ok"
  end

  it "should abort if we use :abort => true" do
    deployer = Deployer.new(:recipe_file => "./test/config/expect.rb", :silent => true)
    t = deployer.__tasks.find {|t| t.__name == :abort_test }
    Runner.stubs(:ssh_exec!).returns(["","fail",1,nil]).then.returns(["ok","",0,nil])
    Runner.execute! t, deployer.__options
    @stdout.size.should == 5
    @stdout[1].should == "    I: (abc.com):  this will fail\n"
    @stderr[0].should == "    O: (abc.com):  fail"
    @stdout[2].should == "    I: (abc.com):  echo 'we failed'\n"
    @stdout[3].should == "    O: (abc.com):  ok"
    @stdout[4].should == "*** END executing task abort_test on test with address abc.com\n\n"
    @stdout[5].should == nil
  end

  #it "should execute :ask and run the appropriate :yes or :no commands" do
  #  deployer = Deployer.new(:recipe_file => "./test/config/ask.rb", :silent => true)
  #  t = deployer.__tasks.find {|t| t.__name == :ask_test }
  #  Runner.execute! t, deployer.__options
  #end

  #it "can prompt for user input and store the input" do
  #  deployer = Deployer.new(:recipe_file => "./test/config/ask.rb", :silent => true)
  #  t = deployer.__tasks.find {|t| t.__name == :prompt_test }
  #  Runner.stubs(:get_input).with("darth vader")
  #  Runner.execute! t, deployer.__options
  #end


  it "should be able to create local tasks" do
    # TODO better testing on this
    lambda { Deployer.new(:recipe_file => "./test/config/local_task.rb", :silent => true).run! :local }.should_not raise_error
  end
end
