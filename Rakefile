require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/screwcap'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'screwcap' do
  self.version  = '0.8.2'
  self.developer 'Grant Ammons', 'grant@pipelinedeals.com'
  self.rubyforge_name       = self.name # TODO this is default value
  self.extra_deps         = [['net-ssh','>= 2.0.23'],['net-ssh-gateway','>=1.0.1'], ['net-scp','>=1.0.4']]
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
remove_task :default
task :default => :spec
