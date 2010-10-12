  # svn address
  svn :url => "http://dev.myapp.com/svn/pipeline_deals/trunk", :user => "grant", :password => "bargains"

  server :prod_servers, :address => "slashdot.org", :user => "test", :key => "id_rsa" do |s|
    s.deploy :dir => "/mnt/app"
    s.mongrel :pid_dir => "#{s.deploy[:dir]}/shared/pids"
    stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
    s.release :dir => "#{s.deploy[:dir]}/releases/#{stamp}"
  end

  task_for :use_server, :server  => :prod_servers do |r|
    r.run "hostname"
    r.release :dir => "something_else"
  end
