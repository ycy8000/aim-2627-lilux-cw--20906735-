#!/bin/bash
# Q4：合并日志，按级别提取，保存首尾片段并统计错误行数。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

mkdir -p "$output"
cat "$input/boot.log" "$input/run.log" > "$output/all.log"
# A grep status of 1 means an empty result; other failures remain errors.
grep '^ERROR ' "$output/all.log" > "$output/errors.log" || [ "$?" -eq 1 ]
grep -E '^(WARN|ERROR) ' "$output/all.log" > "$output/attention.log" || [ "$?" -eq 1 ]
tail -n 5 "$output/all.log" > "$output/recent.log"
head -n 3 "$output/errors.log" > "$output/first-errors.log"
count=$(wc -l < "$output/errors.log")
printf '%d\n' "$count" > "$output/error-count.txt"
