set :deploy_var, "tester"
set :deploy_var_2, "bongo"
set :deploy_var_3, ["one","two"]
server :test, :addresses => ["slashdot.org","google.com"], :user => "root"
server :test2, :addresses => ["bongo.org","bangler.com"], :user => "root"

task_for :task1, :server => :test do
  set :deploy_var_2, "shasta"
  set :bango, "bongo"
  run "deploy dir = #{deploy_var}"
  run "command 2"
  run "command 3"
  run :deploy_var
  run :deploy_var_2
  run :bango
end

task_for :task2, :server => :test do
  set :deploy_var_2, "purple"
  set :deploy_var_3, "mountain dew"
end

task_for :task3, :servers => [:test, :test2] do
  run "ls"
end

task_for :seq1, :server => :test do
  run "1"
end

task_for :seq2, :server => :test do
  run "2"
end

sequence :deploy, :tasks => [:seq1, :seq2]
