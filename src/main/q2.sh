#!/bin/bash
# Q2：创建 sentry_ws 四个子目录、两个空文件以及指定脚本和配置。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

workspace="$output/sentry_ws"
mkdir -p "$workspace"/{scripts,config,logs,tmp}
: > "$workspace/logs/.keep"
: > "$workspace/tmp/scratch.txt"
cat > "$workspace/scripts/hello.sh" <<'EOF'
#!/bin/bash
echo "Hello, AIM Linux!"
EOF
cat > "$workspace/config/robot.conf" <<'EOF'
robot=sentry
mode=training
log_level=INFO
EOF
