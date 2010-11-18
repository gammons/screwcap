set :pie, "moon pie"

server :test, :addresses => ["slashdot.org","google.com"], :user => "root"

command_set :my_command_set do
  run "test"
end

task :my_task, :server => :test do
  run "test"
end
