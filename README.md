# Erhu

<div align="left">
  <a href="https://rubygems.org/gems/erhu" alt="RubyGems Version">
    <img src="https://img.shields.io/gem/v/erhu.svg?style=flat-square&label=current-version" alt="RubyGems Version" />
  </a>
</div>


一个创新的包管理，可以用来管理C语言的包，或者管理算法的包，理论可以用在各种地方，目前主要支持C++，算法管理。

## install
```
gem install erhu
```

## 如何使用

在根目录里面建立`ErhuFile`， 当前也可以使用`erhu init`用于拉取依赖

```ruby
target "./thirdparty"
git "https://github.com/Tencent/rapidjson", tag: "v1.1.0"
git "https://github.com/DaveGamble/cJSON", tag: "v1.7.15"
git "https://github.com/catchorg/Catch2", tag: "v3.3.2"

package "https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.15.zip", name: "cjson"
```

然后就在项目目录中使用 erhu 命令即可拉取对应的代码

示例项目可以看 demo 目录

## 注意事项
1. 请不要随便用git来做依赖管理
2. package只支持zip压缩包，暂时没有计划做其他
3. ErhuFile着色采用ruby编程语言即可，同时整个文件均可执行ruby脚本
4. 判断系统安装对应的包，请看高级用法的系统判断
5. 下载后可以有高级使用办法，比如进入里面继续cmake等等，具体请看高级用法的安装后处理

## 高级用法

### 项目环境变量使用
erhu 集成了dotenv，支持项目中通过.env来指定环境变量，具体可以查看demo目录中的.env文件
.env文件中的环境变量在 `Rakefile` 和 `erhu exec` 中可以使用

### 系统判断

```ruby
# platform.windows?  # => false
# platform.unix?     # => true
# platform.linux?    # => false
# platform.mac?      # => true
if platform.windows?
  package "https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.15.zip", name: "cjson"
end
```

### 安装后处理
> 警告一般不建议这么做，而是采用Rakefile的方式来做处理

```ruby
# 方法定义 git(repository_url, branch: nil, name: nil, tag: nil, &block) 
git "https://github.com/Tencent/rapidjson", tag: "v1.1.0" do |repo, env|
  # repo 的接口请看 https://rubydoc.info/gems/git/Git/Base
  # env 的接口请看 https://github.com/mjason/erhu/blob/main/lib/erhu/app.rb
  # 还有一些高级接口 https://github.com/mjason/erhu/blob/main/lib/erhu/init.rb
end

# 方法定义 package(package_url, name: nil, &block)
package "https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.15.zip", name: "cjson" do |package_file_path, env|
  # package_file_path 下载包的地址，String类型，你得自己解压
  # env 同上

  # 解压示例
  # 
  # zip_file_path: String类型，包含要解压缩的zip文件的路径
  # target_directory: String类型，包含要提取zip文件的位置
  #
  # 该方法使用TTY::Spinner库来显示进度条，并通过调用Zip::File库中的方法来解压缩zip文件。
  # 它迭代zip文件中的每个条目，并使用条目名称中的信息来构造目标路径。
  unzip(package_file_path, "./libs/cjson")
end
```

具体使用案例，可以查看项目里的 demo 目录

## 总结
这是一个很灵活的包管理，希望你用的开心，开源协议MIT