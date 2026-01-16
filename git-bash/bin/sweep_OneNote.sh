#!/bin/bash

set -e

ONENOTE_DIR=/c/Users/zhuoz/BaiduSyncdisk/OneNote

find "$ONENOTE_DIR" -name "OneNote_RecycleBin" -prune -print
find "$ONENOTE_DIR" -name "OneNote_RecycleBin" -prune -exec rm -rf {} +

find "$ONENOTE_DIR" -name "*冲突文件*" -prune -print

find "$ONENOTE_DIR" -name "*冲突文件*" | while read -r conflict_file; do
  dir=$(dirname "$conflict_file")
  base=$(basename "$conflict_file")

  origin_base=$(echo "$base" | sed 's/_冲突文件_.*/.one/')
  origin_file="$dir/$origin_base"

  if [[ -f "$origin_file" ]]; then
    conflict_mtime=$(stat -c %Y "$conflict_file")
    origin_mtime=$(stat -c %Y "$origin_file")

    if ((conflict_mtime > origin_mtime)); then
      echo "冲突文件更新：替换 $origin_file"
      rm -f "$origin_file"
      mv "$conflict_file" "$origin_file"
    else
      echo "原文件更新：删除冲突文件 $conflict_file"
      rm -f "$conflict_file"
    fi
  else
    echo "原文件不存在，直接保留冲突文件 -> 重命名为原文件"
  fi
done
