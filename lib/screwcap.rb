$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'net/ssh'
require 'net/scp'
require 'net/ssh/gateway'
require 'ostruct'
require 'logger'

require 'screwcap/message_logger'
require 'screwcap/base'
require 'screwcap/task'
require 'screwcap/server'
require 'screwcap/runner'
require 'screwcap/sequence'
require 'screwcap/task_manager'

module Screwcap
  VERSION='0.8.1'

  class TaskNotFound < RuntimeError; end
  class NoServersDefined < Exception; end
  class NoServerSelected < Exception; end
  class ConfigurationError < Exception; end
  class IncludeFileNotFound < Exception; end
  class InvalidServer < Exception; end
  class CommandSetDependencyError < Exception; end
  class CommandError < Exception; end
end

