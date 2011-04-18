require 'spec_helper'

unless ENV['USERNAME'] and ENV['KEY'] and ENV['SERVER']
  $stdout << "\nReal world tests will not be run. Please include USERNAME, KEY, and SERVER env vars to run these tests.\n"

else

  describe "Real world test" do
    before(:all) do
      @server = Server.new :name => :server, :address => ENV['SERVER'], :user => ENV['USERNAME'], :key => ENV['KEY']
    end
    it "should be able to run commands and see the result" do
      @task = Task.new :name => :test, :server => :server do
        run "exit 0" do |result|
          puts result
          result.exit_code.should == 0
        end

        run "exit 1" do |result|
          result.exit_code.should == 1
        end
        scp :local => File.expand_path(File.dirname(__FILE__) + "/real_world_spec.rb"), :remote => "/tmp/__real_world_spec.rb"
        run "rm -rf /tmp/__real_world_spec.rb" do |result|
          result.exit_code.should == 0
        end
      end
      @task.__build_commands
      @task.validate([@server])
      Runner.execute! :name => :test, :servers => [@server], :task => @task, :tasks => [@task], :silent => true
    end
  end
end
