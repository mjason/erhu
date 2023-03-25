require 'optparse'

module Erhu
  module_function
  def cli()
    options = {}
    subcommands = {}

    OptionParser.new do |opts|
      opts.banner = "Usage: erhu [command]"
    
      opts.on("-h", "--help", "Prints help") do
        puts """
        erhu init -> init your project
        erhu install(options) -> install your project depends
        """
        exit
      end
    
      # Define global options here
    
    end.parse!

    subcommands['init'] = Proc.new do |args|
      File.open("Erhufile", "w") do |f|
        f.puts 'target "./thirdparty"'
        f.puts 'git "https://github.com/Tencent/rapidjson", tag: "v1.1.0"'
        f.puts 'package "https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.15.zip", name: "cjson"'
      end
      
      # Create Rakefile
      File.open("Rakefile", "w") do |f|
        f.puts 'require "erhu"'
        f.puts
        f.puts 'task :build do |t|'
        f.puts '  Cmd.new().chdir("./build")'
        f.puts '    .run("cmake", "..")'
        f.puts '    .run("make")'
        f.puts 'end'
        f.puts
        f.puts 'task run: [:build] do |t|'
        f.puts '  Cmd.new().chdir("./target").run("./Erhu")'
        f.puts 'end'
      end
    end
    
    subcommands['install'] = Proc.new do |args|
      Erhu::App.new.run
    end

    if ARGV.blank?
      Erhu::App.new.run
    elsif subcommands.key?(ARGV.first)
      subcommands[ARGV.first].call(ARGV[1..-1])
    else
      puts "Invalid command. Use -h or --help for usage information."
    end

  end
end