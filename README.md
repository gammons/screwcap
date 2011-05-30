## Screwcap: dead-simple remote server command running thingy

* http://gammons.github.com/screwcap
* Screwcap is a library that wraps Net::SSH and makes it easy to perform actions on remote servers.

## FEATURES:

* Dead-simple DSL for remote task management.
* Screwcap is not opinionated.  In fact, the only opinion screwcap has is that rails deployment tasks should not be baked into the screwcap core.
* Screwcap is very light on magic and unicorns.  Screwcap recipes are basically only a collection of servers and tasks.  It does not know how to do things unless you tell it how to do things.
* Screwcap is not tied into rake, although it easily can be.
* Screwcap can *easily* be used to deploy rails applications.  
* Rails deployment methodologies change. App servers change. Things change. Because of that, there is nothing rails-deployment-specific about screwcap. Sure, screwcap can easily be used for deploying rails applications, but it's not a one-trick pony.
* Screwcap is proven out in the wild. Here at PipelineDeals, we use screwcap deploy our app to over a dozen different production servers.

## Install
    gem install screwcap

Setting up screwcap for rails is trivial. In your Rails.root, simply run `screwcap --setup-rails`.

## Example

The best way to learn the screwcap DSL is by example.  Here's a detailed example that exercises 95% of what screwcap can do.

```Ruby
server :app_servers, :addresses => ["app1.server.com","app2.server.com"], :user => "appuser", :keys => "~/.ssh/app_key"

set :current_dir, "/mnt/app/current"
set :current_dir, "/mnt/app/shared"

task :rollback do
  run "rake rollback"
end

task :deploy_code, :server => :app_servers do
  scp :local => "~/myfile.txt", :remote => "#{current_dir}/myfile.txt"
  
  run "touch #{current_dir}/tmp/restart.txt" do |result|
    $stderr << result.stderr
    $stdout << result.stdout
    if result.exit_code != 0
      rollback 
    end

    # execute ruby at recipe run-time, not recipe read-time
    ex { raise RuntimeError("it didn't work!") }
  end

  run "cp #{shared_dir}/database.yml #{current_dir}/config/database.yml"
end
```

Running is as simple as `screwcap config/recipes.rb deploy_code`.

## Details

### Servers

Specify a server to run a task on.

```Ruby
server :myserver, :address => "abc.com", :user => "appuser", :keys => "~/.ssh/my_key"
server :another, :addresses => ["abc.com","def.com"], :user => "appuser", :password => "xxx"

gateway :main, :address => "gateway.com", :user => "root", :keys => "~/.ssh/my_key"
server :hidden, :addresses => ["10.10.10.1","10.10.10.2"], :user => "appuser", :password => "xxx", :gateway => :main
```

#### Options
* You can specify a single `:address` or multiple `:addresses` to run a task on.
* Minimally you also need a :user and either :keys or :password to ensure the server is valid.
* You can also specify a :gateway. A gateway is an intermidiary computer between you and the target server. See the example above.


### Tasks

Tasks are a simple collection of commands to run on a server or servers. Tasks can also run other tasks.

#### Options
* `:server` - a server to run the task on
* `:servers` - an array of servers to run the task on.  By default, it will run the same task on all the servers at the same time.  Use `:parallel => false` to make the task run serially.
* `:parallel` - defaults to `true`.  The task will be threaded and run on each server at the same time.  Set to `false` to ensure the task completes on one server before moving to the next.
* `:before` - specify one or an array of tasks to run before this task gets run.
* `:after` - specify one or an array of tasks to run after this task gets run.

#### Task commands

##### `before and `after`
Register a callback either before or after a specified command to run.  These are useful if a task is calling another task.  Example:

```Ruby
  task :deploy do
    create_directory_structure
    checkout_code
    make_symlink
    restart_app_server
  end

  # this particular task needs a minor tweak before making a symlink.
  # this is a good place to use the before command to make that tweak to an otherwise normal task.
  task :deploy_to_set_a, :server => :my_server do
    before :make_symlink do
      clear_previous_symlink
    end
    deploy
  end

  task :deploy_to_set_b, :server => :my_server do
    deploy
  end

```

##### run

`run` will run a command on the specified remote server. Run will yield a block of results.

```Ruby
  task :rollback do
    run "do_rollback"
  end

  task :run_and_yield_results, :server => :myserver do
    run "git clone" do |results|
      $stdout << results.stdout
      $stderr << results.stderr

      rollback if results.exit_code == 0
    end
  end
```

##### ex

`ex` will execute a block of code at recipe runtime.  

```Ruby
  task :app_deploy do
    restart_app_server
    ex { sleep 20 }
    run "verify.sh" do |results|
      if results.exit_code != 0
        ex { $stdout << "Something went wrong!" }
        rollback
      end
    end
  end
```

##### scp

`scp` a file to a remote machine.
```Ruby
  task :add_special_file, :server => :my_server do
    scp :local => 'stats.tgz', :remote => '~/stats.tgz'
    run 'tar -zxvf ~/stats.tgz'
  end
```

##### local

`local` will run a local command on your machine.

```Ruby
  task :collect_stats, :server => :my_server do
    local 'tar -czvf stats.tgz stats/'
    scp :local => 'stats.tgz', :remote => '~/stats.tgz'
  end


#### Putting it together:
```Ruby

# run the multiple_restart command on multiple servers.  Do not execute this task in parallel, but rather 
# execute one server at a time.
task :multiple_restart, :servers => [:myserver, :another], :parallel => false do
  # register a callback within a task.
  after :setup do
    cleanup
  end

  before :setup {  run "rm -rf ~/.setup" }

  # run a local command on your machine.
  local "ls -l"

  # call another task.  This task has before and after handlers defined above.
  setup

  # scp a file from local to remote
  scp :local => "~/numbers.txt", :remote => "/mnt/numbers.txt"

  # execute a ruby statement at recipe run-time, not recipe load-time
  ex { $stdout << "about to touch restart.txt" }

  # run a command on the server and do something with the results
  run "touch /tmp/restart.txt" do |results|
    if results.exit_code != 0
      ex { $stderr << "Something went wrong!  bailing out!" }
      bail_out
    end
  end
  cleanup
end
```


## Copyright

Copyright (c) 2011 Grant Ammons. See LICENSE.txt for further details.
