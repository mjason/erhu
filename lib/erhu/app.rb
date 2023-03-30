module Erhu
  class App
    attr_accessor :erhufile
    def initialize(erhufile_path=nil)
      @erhufile = erhufile_path || File.join(Dir.pwd, "ErhuFile")

      @erhu_path = File.join(Dir.pwd, ".erhu")
      unless Dir.exist?(@erhu_path)
        FileUtils.mkdir_p(@erhu_path)
        puts "Created #{@erhu_path}"
      end
      @database_path = File.join(@erhu_path, "database.yml")
    end

    def database
      if File.exist?(@database_path)
        @database ||= YAML.load_file(@database_path) || {}
      else
        @database ||= {}
      end
    end

    def target(path)
      @target = path
      unless Dir.exist?(@target)
        FileUtils.mkdir_p(@target)
        puts "Created #{@target}"
      end
    end

    def git(repository_url, branch: nil, name: nil, tag: nil, &block)
      name = name || File.basename(URI.parse(repository_url).path, '.git')
      
      info = self.database.fetch(name, {})
      info.delete(:commit)
      if info == {repository_url: repository_url, branch: branch, name: name, tag: tag}
        puts "ignore #{repository_url}"
        return
      else
        FileUtils.rm_rf("#{@target}/#{name}")
      end

      warn!("Do not use Git for version control without careful consideration.")

      spinner = TTY::Spinner.new("[:spinner] git clone #{repository_url} ...")
      spinner.auto_spin
      repo = Git.clone(repository_url, "#{@target}/#{name}", branch: branch)
      unless tag.blank?
        
        tags = repo.tags
        if tags.map { |tag| tag.name }.include?(tag)
          commit_id = tags.select { |node| node.name == tag }.first.objectish
          repo.checkout(tag, start_point: commit_id, new_branch: true)
        end
      end
      spinner.stop("Done!")

      block.call(repo, self) unless block.blank?

      self.database[name] = {repository_url: repository_url,
        branch: branch, name: name, tag: tag, commit: repo.revparse('HEAD')
      }
    rescue => e
      error! e
    end

    def package(package_url, name: nil, &block)
      raise "package url is required" if package_url.blank?
      raise "name: 'package name' is required" if name.blank?
      
      package_name = name
      package_hex = name.unpack('H*').first
      package_file_path = "#{@erhu_path}/#{package_name}-#{package_hex}.zip"
      
      if File.exist?(package_file_path)
        puts "ignored #{package_url}"
        return
      end

      bar = TTY::ProgressBar.new("downloading #{package_name} :percent [:bar]", total: 50)
      total_size = 0

      http.download package_url, destination: package_file_path,
        content_length_proc: -> (content_length) {
          total_size = content_length
        },
        progress_proc: -> (progress) {
          if total_size > 0
            bar.ratio = progress / total_size.to_f
          end
        }
      bar.finish

      unless block.blank?
        block.call(package_file_path, self)
        return
      end

      self.zip(package_file_path, package_name)
    end

    def zip(package_file_path, package_name)
      unzip(package_file_path, File.join(@target, package_name))
    end

    def run
      instance_eval File.read(@erhufile), @erhufile, 1
      File.open(@database_path, 'w') do |file|
        file.write self.database.to_yaml
      end
    end
  end
end