require "tty-command"
require "tty-platform"
require "tty-progressbar"
require "tty-spinner"
require "pastel"
require 'fileutils'
require "uri"
require 'yaml'
require 'faraday'
require 'faraday/follow_redirects'
require 'tempfile'
require 'zip'
require 'git'
require 'optparse'

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

def platform
  $platform ||= TTY::Platform.new
end

def pastel
  $pastel ||= Pastel.new
end

def error!(*args)
  error = pastel.red.bold.detach
  puts "Error: #{error.(*args)}"
end

def warn!(*args)
  warning  = pastel.yellow.detach
  puts "Warning: #{warning.(*args)}"
end

class Cmd
  def initialize(pty: true, uuid: false, color: true, printer: :pretty)
    @cmd = TTY::Command.new(pty: pty, uuid: uuid, color: color, pretty: printer)
  end

  def chdir(path)
    @chdir = path
    self
  end

  def run(*args, &block)
    options = args.last.is_a?(Hash) ? args.pop : {}
    options[:chdir] = options.fetch(:chdir, @chdir)
    args << options
    @cmd.run(*args, &block)
    self
  rescue => e
    error! e
  end
end