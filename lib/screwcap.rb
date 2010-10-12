$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'net/ssh'

require 'screwcap/base'
require 'screwcap/command_set'
require 'screwcap/task'
require 'screwcap/server'
require 'screwcap/deployer'
