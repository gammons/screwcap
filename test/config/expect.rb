server :test, :address => "abc.com", :user => "root"
set :variable, 1

command_set :revert do
  run "revert"
end

task_for :logic, :server => :test do
  case variable
  when 1
    run "1"
  when 2
    run "2"
  else
    run "none"
  end
end

command_set :fail do
  run "ls"
end

command_set :success do
  run "ls"
end

task_for :expect, :server => :test do 
  run "ls", :onfail => :fail, :onsuccess => :success
end

