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

# 添加多个tags
tags:
  - tag1
  - tag2
<tab>-<space>tagname
