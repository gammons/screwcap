set :deploy_var, "tester"
set :deploy_var_2, "bongo"
set :deploy_var_3, ["one","two"]
server :test, :addresses => ["slashdot.org","google.com"], :user => "root", :key => "id_rsa"

command_set :push_to_thang do
  run :deploy_var
  run "run with #{deploy_var}"
  run :deploy_var_2
end

command_set :task_only_var do
  run :task_var
end

command_set :set_var do
  set :deploy_var, "dingle"
  run :deploy_var
end

command_set :nested do
  run "3"
  run "4"
end

command_set :simple1 do
  run "1"
  run "2"
  nested
end

command_set :really_simple do
  run "1"
  run "2"
  run "3"
end

command_set :nested_inside_with_var do
  set :nested_var, "nested"
  run :nested_var
end

command_set :nested_outside_with_var do
  set :nested_var, "birdo"
  run :nested_var
  nested_inside_with_var
  run :nested_var
end


task_for :use_command_set_no_override, :server => :test do
  push_to_thang
end

task_for :use_command_set_with_override, :server => :test do
  set :deploy_var, "shasta"
  push_to_thang
end

task_for :use_command_set_complex_override, :server => :test do
  set :deploy_var, "bango"
  set_var
end

task_for :nested_command_set, :server => :test do
  simple1
end

task_for :really_simple_task, :server => :test do
  really_simple
end

task_for :task_set_var, :server => :test do
  set :task_var, "bojangles"
  task_only_var
end

task_for :command_set_override, :server => :test do
  set :deploy_var, "bubbles"
  set_var
end

task_for :nested_scoping, :server => :test do
  set :nested_var, "task"
  nested_outside_with_var
  run :nested_var
end
