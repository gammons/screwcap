  server :test, :address => "test.com", :user => "root"

  # set a global var
  global_var 1
  global_hash :test => "margin"

  command_set :uses_global_var do |cs|
    # use the global var in a command set
    cs.run "ls -l _var_", :global_var
  end

  command_set :uses_global_hash do |cs|
    # use the global var in a command set
    cs.run "hashval is _var_", "global_hash[:test]"
  end

  command_set :uses_multiple do |cs|
    cs.run "thing is _var_, another thing is _var_", :global_var, "global_hash[:test]"
  end

  command_set :using_undefined_var do |cs|
    cs.run "_var_", :undefined_var
  end

  task_for :redefine_var, :server => :test do |r|
    # redefine the global var in the task
    r.global_var 2
    r.uses_global_var
  end

  task_for :keep_var, :server => :test do |r|
    # redefine the global var in the task
    r.uses_global_var
  end

  task_for :redefine_var_again, :server => :test do |r|
    # redefine the global var in the task
    r.global_var "blargin"
    r.uses_global_var
  end

  task_for :redefine_hash, :server => :test do |r|
    r.global_hash :test => "blargo"
    r.uses_global_hash
  end

  task_for :do_not_redefine_hash, :server => :test do |r|
    r.uses_global_hash
  end

  task_for :redefine_one_not_other, :server => :test do |r|
    r.global_var 2
    r.uses_multiple
  end

  task_for :redefine_one_not_other_2, :server => :test do |r|
    r.global_hash :test => "mango"
    r.uses_multiple
  end

  task_for :redefine_both, :server => :test do |r|
    r.global_var 5
    r.global_hash :test => "mango"
    r.uses_multiple
  end

  task_for :undefined_var, :server => :test do |r|
    r.using_undefined_var
  end
