#!/usr/bin/env bash
# SIGTERM every claude/copilot process across every pane on the server.
# Leaves shells intact.

set -u

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

list_descendants() {
    local parent="$1" child
    for child in $(ps -o pid= --ppid "$parent" 2>/dev/null); do
        echo "$child"
        list_descendants "$child"
    done
}

killed=0
while read -r pane_pid; do
    [ -z "$pane_pid" ] && continue
    for pid in $(list_descendants "$pane_pid"); do
        cmd="$(ps -o args= -p "$pid" 2>/dev/null)"
        case "$cmd" in
            *"gh copilot"*|*"github-copilot-cli"*|*/copilot|*"copilot-cli"*|\
            *"claude "*|*/claude|"claude"|*"claude-code"*|*"@anthropic-ai/claude-code"*)
                kill -TERM "$pid" 2>/dev/null && killed=$((killed + 1))
                ;;
        esac
    done
done < <(tmux list-panes -a -F '#{pane_pid}')

tmux display-message "tmux-ai: sent SIGTERM to $killed AI process(es)"
"$CURRENT_DIR/detect.sh" >/dev/null 2>&1 &
