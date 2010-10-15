$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'net/ssh'
require 'net/ssh/gateway'
require 'ostruct'

require 'screwcap/base'
require 'screwcap/command_set'
require 'screwcap/task'
require 'screwcap/server'
require 'screwcap/deployer'


module Screwcap
  VERSION="0.0.1"

  class TaskNotFound < RuntimeError; end
  class NoServersDefined < Exception; end
  class NoServerSelected < Exception; end
  class ConfigurationError < Exception; end
  class IncludeFileNotFound < Exception; end
  class InvalidServer < Exception; end
  class CommandSetDependencyError < Exception; end
end

