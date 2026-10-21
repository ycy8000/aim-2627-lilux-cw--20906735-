#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

source "$input/process.env"
mkdir -p "$output"

is_running() {
    local state
    state=$(ps -p "$1" -o stat=) || return 1
    # A zombie has exited, even if its parent has not reaped it yet.
    [[ -n "$state" && "$state" != *Z* ]]
}

stop_process() {
    local pid=$1 attempt
    if ! is_running "$pid"; then
        return 0
    fi
    kill -TERM "$pid"
    for ((attempt = 0; attempt < 40; attempt++)); do
        if ! is_running "$pid"; then
            return 0
        fi
        sleep 0.05
    done
    printf 'Process %s did not stop in time\n' "$pid" >&2
    return 1
}

case "$action" in
    repair)
        details=$(ps -ww -p "$TARGET_PID" -o pid=,user:32=,stat=,args=)
        read -r pid owner state command <<< "$details"
        if [[ "$command" != *"$TARGET_TOKEN"* ]]; then
            printf 'Target process does not match its token\n' >&2
            exit 1
        fi
        printf 'pid=%s\nuser=%s\nstate=%s\ncommand=%s\n' \
            "$pid" "$owner" "$state" "$command" > "$output/process.txt"
        cp "$WORKER_LOG" "$output/collector-sample.log"
        stop_process "$TARGET_PID"
        stop_process "$SERVICE_PID"

        printf 'bind=127.0.0.1\nport=%s\nroute=/status\n' \
            "$TARGET_PORT" > "$output/server.conf"
        bash "$START_TOOL" "$output/server.conf" "$output/service"

        # Retry only for a bounded interval and record the actual HTTP response.
        for ((attempt = 0; attempt < 30; attempt++)); do
            if curl --noproxy '*' --silent --show-error \
                --connect-timeout 0.2 --max-time 0.2 \
                --output "$output/http-body.txt" --write-out '%{http_code}\n' \
                "http://127.0.0.1:$TARGET_PORT/status" > "$output/http-status.txt"; then
                if [ "$(cat "$output/http-status.txt")" = 200 ] && \
                    [ "$(cat "$output/http-body.txt")" = 'SENTRY READY' ]; then
                    exit 0
                fi
            fi
            sleep 0.1
        done
        stop_process "$(cat "$output/service/pid")"
        printf 'Repaired service did not become ready\n' >&2
        exit 1
        ;;
    cleanup)
        pid=$(cat "$output/service/pid")
        if is_running "$pid"; then
            command=$(ps -ww -p "$pid" -o args=)
            if [[ "$command" != *"$output/server.conf"* ]]; then
                printf 'Saved PID does not belong to this service\n' >&2
                exit 1
            fi
            stop_process "$pid"
        fi
        ;;
    *)
        printf 'Unknown action: %s\n' "$action" >&2
        exit 2
        ;;
esac
