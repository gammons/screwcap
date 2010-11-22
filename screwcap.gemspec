# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'bundler/version'
 
Gem::Specification.new do |s|
  s.name        = "screwcap"
  s.version     = "0.6.pre6"
  s.platform    = Gem::Platform::RUBY
  s.author     = "Grant Ammons"
  s.email       = ["grant@pipelinedealsco.com"]
  s.homepage    = "http://github.com/gammons/screwcap"
  s.summary     = "Screwcap is a wrapper of Net::SSH and allows for easy configuration, organization, and management of running tasks on remote servers."
 
  s.add_dependency(['net-ssh','>=2.0.23'])
  s.add_dependency(['net-ssh-gateway','>=1.0.1'])
  s.add_dependency(['net-scp','>=1.0.4'])
  s.rubyforge_project = 'screwcap'
 
  s.files        = Dir.glob("{bin,lib}/**/*") + %w(README.rdoc screwcap.gemspec)
  s.require_path = 'lib'
end
