server :default_server, :address => "slashdot.org", :user => "root", :password => "none" 

def do_something_else_before command
  @options[:before_method_2] = true
end

def do_something_before command
  @options[:before_method] = true
end

def do_something_after  command
  @options[:after_method] = true
end

task_for :something, :server => :default_server do |r|
  r.run "hostname", :before => :do_something_before
  r.run "hostname", :before => [:do_something_before, :do_something_else_before]
  r.run "hostname2", :after => :do_something_after
  r.run "hostname2", :after => [:do_something_after, :do_something_after]
end
