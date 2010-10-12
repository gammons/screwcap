  svn :url => "http://blah", :username => "joe", :password => "embiggens"

  server :default_server, :address => "slashdot.org", :user => "root" do |s|
    s.apache :dir => "asdf"
    s.deploy :dir => "/home/deploy"
  end

  command_set :link_it do |c|
    c.run "link it"
  end

  command_set :dependent_set, :depends => :link_it do |c|
    c.run "command 1"
    c.run "command 2"
    c.run "command 3"
  end


  task_for :unmet_dep, :server => :default_server do |r|
    r.dependent_set
  end

  task_for :all_met_deps, :server => :default_server do |r|
    r.link_it
    r.dependent_set
  end
