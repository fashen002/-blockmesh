#!/bin/bash

# 检查目录是否存在
if [ ! -d "/root/Goat_bot" ]; then
    # 创建目录
    mkdir -p "/root/Goat_bot"
fi
# 检查文件是否存在
if [ -e "/root/Goat_bot/data.txt" ]; then
    # 如果是文件夹，则删除
    if [ -d "/root/Goat_bot/data.txt" ]; then
        rm -rf "/root/Goat_bot/data.txt"
        # 创建新的文本文件
        touch "/root/Goat_bot/data.txt"
        echo "Created new data.txt file"
    fi
else
    # 创建新的文本文件
    touch "/root/Goat_bot/data.txt"

    # 打印日志
    echo "Created new data.txt file"
fi



