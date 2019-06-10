#!/bin/sh

rm -rf /var/www/html/*
echo "删除完成..."
cp -r /root/blog/public/. /var/www/html
echo "复制完成..."

