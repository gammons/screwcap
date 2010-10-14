set :deploy_var, "tester"
set :deploy_var_2, "bongo"
set :deploy_var_3, ["one","two"]
server :test, :addresses => ["slashdot.org","google.com"], :user => "root", :key => "id_rsa"

command_set :push_to_thang do
  run :deploy_var
  run "run with #{deploy_var}"
  run :deploy_var_2
end

task_for :use_command_set_no_override, :server => :test do
  push_to_thang
end

task_for :use_command_set_with_override, :server => :test do
  set :deploy_var, "shasta"
  push_to_thang
end
