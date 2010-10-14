deploy_dir = "/mnt/app"
git = {:url => "http://dev.myapp.com/svn/pipeline_deals/trunk", :user => "grant", :password => "bargains"}
#
server :test, :addresses => ["slashdot.org","google.com"], :user => "root", :key => "id_rsa"

task_for :task1, :server => :test do
  deploy_dir "/home/rails"
  bango "bongo"
  run "deploy dir = #{deploy_dir}"
  run "command 2"
end

#task_for :task2, :server => :test do
#  deploy_dir = "/home/rails"
#  run "ls -l"
#end
