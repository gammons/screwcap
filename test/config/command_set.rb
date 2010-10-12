
  server :default_server, :address => "slashdot.org", :user => "root", :password => "none" 

  apache :dir => "asdf"
  deploy :dir => "/home/deploy"
  svn :url => "http://blah", :username => "joe", :password => "embiggens"

  command_set :svn_check_out do |c|
    c.svn :url => "http://blah2", :username => "joe", :password => "embiggens"
    c.apache :dir => "overridden"
    c.release_dir "#{c.deploy[:dir]}/releases/#{Time.now.to_i}", "deploy[:dir]"
    p "release_dir = #{c.release_dir}"
    c.run "mkdir -p #{c.release_dir}"
    c.run "svn co #{c.svn[:url]}"
  end

  command_set :use_global_options do |c|
    c.release_dir c.apache[:dir]
    c.run c.release_dir
  end

  command_set :link_it do |c|
    c.run "command 1"
  end

  command_set :restart_apache do |c|
    c.run "command 1"
    c.run "command 2"
    c.run "command 3"
  end

  command_set :dependent_set, :depends => :link_it do |c|
    c.run "command 1"
    c.run "command 2"
    c.run "command 3"
  end


  task_for :test_command_sets, :server => :default_server do |r|
    r.restart_apache
  end

  task_for :all_met_deps, :server => :default_server do |r|
    r.link_it
    r.dependent_set
  end

  task_for :run_check_out, :server => :default_server do |r|
    r.svn_check_out
    r.use_global_options
  end

