require 'stringio'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/screwcap'

require 'rubygems'
require 'mocha'
require 'ruby-debug' rescue nil
require 'net/ssh'

class SSHObject
  attr_accessor :options

  def initialize(options = {})
    @options = {:return_stream => :stdout}
    @options = options
  end

  def exec!(cmd, &block)
    yield nil, @options[:return_stream], @options[:return_data]
  end

  def ssh(address, user, options = {}, &block)
    yield nil
  end
end
