server :test, :address => "slashdot.org", :user => "root"
task_for :upload, :server => :test do
  scp :local => "/tmp/grant", :remote => "tmp/grant"
end
