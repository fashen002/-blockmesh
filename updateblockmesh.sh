#!/bin/bash

# 从命令行参数获取文件名
filename=\$1

# 检查文件是否存在
if [ -e "$filename" ]; then
    # 如果是文件夹，则删除
    if [ -d "$filename" ]; then
        rm -rf "$filename"
    fi
fi

# 创建新的文本文件
touch "$filename"
