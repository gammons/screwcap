gateway :gateway1, :address => "slashdot.org", :user => "root"
server :test, :addresses => ["bongo.org","bangler.com"], :user => "root", :gateway => :gateway1
server :test2, :address => "bangler.com", :user => "root", :gateway => :gateway1

task_for :task1, :server => :test do
  run "ls"
end

