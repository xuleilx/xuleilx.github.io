#!/bin/sh

hexo new $1
read -p "Please update date the file, and press any key to continue..." key
hexo g --config source/_data/next.yml
hexo d --config source/_data/next.yml
