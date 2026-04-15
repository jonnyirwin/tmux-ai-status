#!/usr/bin/env bash
# Single-instance background loop that periodically rescans for AI processes.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_DIR="${TMPDIR:-/tmp}/ai-tmux-plugin-$(id -u)"
PID_FILE="$LOCK_DIR/daemon.pid"

mkdir -p "$LOCK_DIR"

case "${1:-start}" in
    start)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            exit 0
        fi
        (
            echo $$ > "$PID_FILE"
            trap 'rm -f "$PID_FILE"; exit' TERM INT EXIT
            while tmux has-session 2>/dev/null; do
                interval="$(tmux show-option -gqv '@ai_refresh_interval')"
                [ -z "$interval" ] && interval=5
                "$CURRENT_DIR/detect.sh" >/dev/null 2>&1
                sleep "$interval"
            done
        ) </dev/null >/dev/null 2>&1 &
        disown
        ;;
    stop)
        [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
        ;;
esac
