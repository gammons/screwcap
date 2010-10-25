require 'stringio'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/screwcap'

require 'rubygems'
require 'mocha'
require 'ruby-debug' rescue nil
require 'net/ssh'

class SSHObject < OpenStruct
  attr_accessor :options

  def initialize(options = {})
  end

  def on_data
    yield SSHObject.new, ""
  end

  def on_extended_data
    yield SSHObject.new, "", ""
  end

  def read_long
    ""
  end

  def upload!(from, to)
    nil
  end

  def scp
    SSHObject.new
  end

  def on_request(item)
    yield SSHObject.new, SSHObject.new
  end
end
