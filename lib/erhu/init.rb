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
require 'rubygems/package'
require 'zlib'
require 'uri'

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

def ungzip(tar_gz_archive, destination)
  spinner = TTY::Spinner.new("[:spinner] extracted :title ...")
  spinner.auto_spin
  Gem::Package::TarReader.new( Zlib::GzipReader.open tar_gz_archive) do |tar|
    dest = nil
    tar.each do |entry|
      spinner.update title: entry.full_name
      if entry.full_name == '././@LongLink'
        dest = File.join destination, entry.read.strip
        next
      end
      dest ||= File.join destination, entry.full_name.split('/')[1..-1].join('/')
      if entry.directory?
        FileUtils.rm_rf dest unless File.directory? dest
        FileUtils.mkdir_p dest, :mode => entry.header.mode, :verbose => false
      elsif entry.file?
        FileUtils.rm_rf dest unless File.file? dest
        File.open dest, "wb" do |f|
          f.print entry.read
        end
        FileUtils.chmod entry.header.mode, dest, :verbose => false
      elsif entry.header.typeflag == '2' #Symlink!
        File.symlink entry.header.linkname, dest
      end
      dest = nil
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

def extract_extension(url)
  uri = URI.parse(url)
  path = uri.path

  if path.end_with?('.tar.gz')
    '.tar.gz'
  else
    File.extname(path)
  end
end