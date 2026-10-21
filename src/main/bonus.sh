#!/bin/bash
# Bonus：start 时创建分离的 tmux 会话和采集器；stop 时正常停止采集器并结束会话。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-start}

source "$input/bonus.env"
mkdir -p "$output"

case "$action" in
    start)
        if ! tmux -L "$TMUX_SOCKET" has-session -t "=$SESSION" 2>/dev/null; then
            printf -v command 'exec python3 %q --token %q --log %q' \
                "$WORKER_TOOL" "$TOKEN" "$output/bonus.log"
            tmux -L "$TMUX_SOCKET" new-session -d -s "$SESSION" "$command"
        fi
        ;;
    stop)
        if tmux -L "$TMUX_SOCKET" has-session -t "=$SESSION" 2>/dev/null; then
            pid=$(tmux -L "$TMUX_SOCKET" display-message -p \
                -t "=$SESSION:" '#{pane_pid}')
            kill -TERM "$pid"
            stopped=false
            for ((attempt = 0; attempt < 40; attempt++)); do
                state=$(ps -p "$pid" -o stat=) || state=
                if [[ -z "$state" || "$state" == *Z* ]]; then
                    stopped=true
                    break
                fi
                sleep 0.05
            done
            if [ "$stopped" != true ]; then
                printf 'Collector did not stop in time\n' >&2
                exit 1
            fi
            # The session usually ends automatically when its only pane exits.
            if tmux -L "$TMUX_SOCKET" has-session -t "=$SESSION" 2>/dev/null; then
                tmux -L "$TMUX_SOCKET" kill-session -t "=$SESSION"
            fi
        fi
        ;;
    *)
        printf 'Unknown action: %s\n' "$action" >&2
        exit 2
        ;;
esac
