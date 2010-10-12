  server :test, :address => "slashdot.org", :user => "asdf", :key => "id_rsa"

  task_for :success, :server => :test do |r|
    r.run "hostname"
  end

  task_for :stop_on_errors, :server => :test do |r|
    r.continue_on_errors false
    r.run "hostname1"
    r.run "hostname2"
  end
