#!/bin/bash

# 从命令行参数获取文件名
filename="\$1"

# 检查文件是否存在
if [ -e "$filename" ]; then
    # 判断文件类型
    if [ -d "$filename" ]; then
        # 如果是文件夹，则删除并创建新的文本文件
        rm -rf "$filename"
        echo "文件夹 $filename 被删除"
        mkdir "$filename" && echo "文件夹 $filename 创建成功"
    elif [ -f "$filename" ]; then
        # 如果是文本文件，则打印文件类型
        echo "文件 $filename 是文本文件"
    else
        # 其他类型文件
        echo "文件 $filename 不是文本文件"
    fi
else
    # 创建新的文本文件
    touch "$filename"
    echo "文件 $filename 被创建"
fi
