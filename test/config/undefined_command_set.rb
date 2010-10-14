server :test, :addresses => ["slashdot.org","google.com"], :user => "root", :key => "id_rsa"

command_set :has_undefined do
  this_is_undefined
end

task_for :task, :server => :test do
  has_undefined
end
