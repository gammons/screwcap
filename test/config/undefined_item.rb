server :test, :addresses => ["slashdot.org","google.com"], :user => "root", :key => "id_rsa"
task_for :undefined_thing, :server => :test do
  this_is_undefined
end
