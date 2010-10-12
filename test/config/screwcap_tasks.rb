  # default deploy directory
  deploy_dir "/mnt/app"

  # svn address
  svn :url => "http://dev.yourapp.com/svn/pipeline_deals/trunk", :user => "grant", :password => "bargains"

  # mongrel options
  mongrel :pid_dir => "/home/rails/pipelinedeals/shared/pids"

  recipe_for :q_servers do |r|
    r.servers ["q.server1.com","q2.server2.com"], :user => "root", :key => "my_key"
    r.run "/mnt/app/current/script/poller stop"
    r.check_out
    r.symlink
    r.run "cp #{r.release_dir}/config/database.yml.prod #{r.release_dir}/config/database.yml"
    r.run "/mnt/app/current/script/poller start"
  end

  recipe_for :quick_deploy do |r|
    r.servers ["slashdot.org","slashdot2.org"]
  end

  recipe_for :quick_deploy_test do |r|
    r.servers ["slashdot.org"], :user => :root, :key => "my_key"
    r.run "svn info /home/rails/yourapp/current"
    r.params.each do |param|
      r.run "svn up /home/rails/yourapp/current/#{param}" 
    end
  end
