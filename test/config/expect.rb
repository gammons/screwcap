server :test, :address => "abc.com", :user => "root"
set :variable, 1

command_set :revert do
  run "revert"
end

command_set :failover do
  run "echo 'we failed'"
end

task_for :expect, :server => :test do 
  run "this will fail", :onfailure => :failover
  run "ls"
end

