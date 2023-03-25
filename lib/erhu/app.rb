module Erhu
  class App
    attr_accessor :erhufile
    def initialize(erhufile_path=nil)
      @erhufile = erhufile_path || File.join(Dir.pwd, "erhuFile")

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

      conn = Faraday.new do |faraday|
        faraday.use Faraday::FollowRedirects::Middleware
        faraday.adapter Faraday.default_adapter
      end

      bar = TTY::ProgressBar.new("Downloading #{package_name} [:bar] :percent", total: 50, interval: 0.1)

      streamed = []
      response = conn.get(package_url) do |req|
        req.options.on_data = Proc.new do |chunk, overall_received_bytes, env|
          content_length = env.response_headers["content-length"]&.to_f
          bar.ratio = overall_received_bytes / content_length if !content_length.blank? && content_length > 0
          streamed << chunk
        end
      end

      File.open(package_file_path, 'w') do |f|
        f.write(streamed.join)
      end

      unless block.blank?
        block.call(package_file_path, self)
        return
      end

      self.zip(package_file_path, package_name)
    end

    def zip(package_file_path, package_name)
      spinner = TTY::Spinner.new("[:spinner] extracted :title ...")
      spinner.auto_spin

      Zip::File.open(package_file_path) do |zip_file|
        zip_file.each do |entry|        
          dest_path = File.join(@target, package_name, entry.name.split('/')[1..-1].join('/'))
          entry.extract(dest_path)
          spinner.update title: entry.name
        end
      end
      spinner.update title: "ALL"
      spinner.stop("Done!")
    end

    def run
      instance_eval File.read(@erhufile), @erhufile, 1
      File.open(@database_path, 'w') do |file|
        file.write self.database.to_yaml
      end
    end
  end
end