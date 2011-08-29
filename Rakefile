require 'bundler'
Bundler::GemHelper.install_tasks

Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
task :default => :spec
