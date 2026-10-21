#!/bin/bash
# Q1：定位 handover，读取隐藏编号和欢迎文本。输出 location.txt、robot-id.txt、welcome.txt。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

mkdir -p "$output"
(cd -- "$input/handover" && pwd -P) > "$output/location.txt"
cat "$input/handover/.robot-id" > "$output/robot-id.txt"
cat "$input/notes/welcome.txt" > "$output/welcome.txt"
