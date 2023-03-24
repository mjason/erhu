# Erhu

一个创新的包管理，可以用来管理C语音的包，或者管理算法的包，理论可以用在各种地方，目前主要支持C++，算法管理。

## install
```
gem install erhu
```

## 如何使用

在根目录里面建立`ErhuFile`，用于拉取依赖

```ruby
target "./thirdparty"
git "https://github.com/Tencent/rapidjson", tag: "v1.1.0"
git "https://github.com/DaveGamble/cJSON", tag: "v1.7.15"
git "https://github.com/catchorg/Catch2", tag: "v3.3.2"

package "https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.15.zip", name: "cjson"
```

然后就在项目目录中使用 erhu 命令即可拉取对应的代码

示例项目可以看 example 目录