  # default deploy directory
  deploy :dir => "/mnt/app"

  deploy_dir = "/mnt/app"

  # svn address
  svn :url => "http://dev.myapp.com/svn/pipeline_deals/trunk", :user => "grant", :password => "bargains"

  # mongrel options
  mongrel :pid_dir => "/home/rails/my_app/shared/pids"

  server :test, :addresses => ["slashdot.org","digg.com"], :user => "root", :key => "id_rsa"

  task_for :no_override, :server => :test do |r|
    r.run "hostname"
  end

  task_for :override, :server => :test do |r|
    r.deploy_dir "/home/rails"
    r.mongrel :pid_dir => "/home/rails/my_app2/shared/pids"
    r.svn  :url => "my.svn.com", :user => "grant", :password => "bingo"
  end
