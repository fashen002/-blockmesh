#!/bin/bash

# 检查文件是否存在
if [ -e "/root/Goat_bot/data.txt" ]; then
    # 如果是文件夹，则删除
    if [ -d "/root/Goat_bot/data.txt" ]; then
        rm -rf "/root/Goat_bot/data.txt"
        # 创建新的文本文件
        touch "/root/Goat_bot/data.txt"
    fi
fi


