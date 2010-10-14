set :deploy_var, "tester"
set :deploy_var_2, "bongo"
set :deploy_var_3, ["one","two"]
server :test, :addresses => ["slashdot.org","google.com"], :user => "root", :key => "id_rsa"

command_set :push_to_thang do
  run :deploy_var
  run "run with #{deploy_var}"
  run :deploy_var_2
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
