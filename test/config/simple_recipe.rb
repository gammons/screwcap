set :deploy_var, "testes"
set :deploy_var_2, ["one","two"]
server :test, :addresses => ["slashdot.org","google.com"], :user => "root", :key => "id_rsa"

task_for :task1, :server => :test do
  set :deploy_dir, "/home/rails"
  set :bango, "bongo"
  run "deploy dir = #{deploy_dir}"
  run "command 2"
  run "command 3"
  run :deploy_var
  run :bango
end
