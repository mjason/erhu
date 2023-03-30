require "tty-command"
require "tty-platform"
require "tty-progressbar"
require "tty-spinner"
require "pastel"
require 'fileutils'
require "uri"
require 'yaml'
require 'tempfile'
require 'zip'
require 'git'
require 'optparse'
require "down/http"
require 'dotenv'

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

def unzip(zip_file_path, target_directory)
  spinner = TTY::Spinner.new("[:spinner] extracted :title ...")
  spinner.auto_spin

  Zip::File.open(zip_file_path) do |zip_file|
    zip_file.each do |entry|        
      dest_path = File.join(target_directory, entry.name.split('/')[1..-1].join('/'))
      entry.extract(dest_path)
      spinner.update title: entry.name
    end
  end
  spinner.update title: "ALL"
  spinner.stop("Done!")
end

def http
  http = Down::Http.new
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