```shell
# 安装hexo
hexo官网，安装hexo
注意：不要安装在git仓库目录下安装hexo，会在当前目录生产node_modules
cd ~
npm install --save hexo-deployer-git
apt-get -y install build-essential nghttp2 libnghttp2-dev libssl-dev

# 创建博客
hexo new [layout] <title>
#hexo clean # can not deploy, try this
hexo g --config source/_data/next.yml
hexo d --config source/_data/next.yml

用户名：xuleilx@gmail.com
密码：github网页 Setting -> Developer setting -> Personal access tokens -> 更新Token，拷贝，粘贴

# images path
themes/next/source/images/

# You can use:
./post.sh <title>

# 启动本地服务：
hexo s --config source/_data/next.yml

# upload source 
git checkout hexo
git pull
hexo clean
git add source themes
git commit
git push origin hexo
```
# VPN设置代理
```text
Windows PC翻墙，虚拟机不要设置代理
#1.设置全局代理 setting -> networking
#2. git设置代理
#git config --global http.proxy http://192.168.23.40:7890
#git config --global https.proxy https://192.168.23.40:7890
```
# 添加多个tags
```text
tags:
  - tag1
  - tag2
categories:
 - name
<space>-<space>tagname
```
