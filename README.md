```shell
hexo new [layout] <title>
#hexo clean # can not deploy, try this
hexo g --config source/_data/next.yml
hexo d --config source/_data/next.yml

# images path
themes/next/source/images/

# You can use:
./post.sh <title>

# 启动本地服务：
hexo s --config source/_data/next.yml

# upload source 
git checkout hexo
hexo clean
git add source themes
git commit
git push origin hexo
```
# VPN设置代理
```text
1.设置全局代理 setting -> networking
2. git设置代理
git config --global http.proxy http://192.168.152.1:1080
git config --global https.proxy https://192.168.152.1:1080
```
# 添加多个tags
```text
tags:
  - tag1
  - tag2
<tab>-<space>tagname
```
