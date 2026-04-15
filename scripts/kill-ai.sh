#!/usr/bin/env bash
# Kill the AI process (claude / copilot) running inside the given pane.
# Leaves the pane's shell intact. Usage: kill-ai.sh <session>:<window>.<pane>

set -u

target="${1:-}"
if [ -z "$target" ]; then
    tmux display-message "kill-ai: no target pane given"
    exit 1
fi

pane_pid="$(tmux display-message -p -t "$target" '#{pane_pid}' 2>/dev/null)"
if [ -z "$pane_pid" ]; then
    tmux display-message "kill-ai: pane $target not found"
    exit 1
fi

list_descendants() {
    local parent="$1" child
    for child in $(ps -o pid= --ppid "$parent" 2>/dev/null); do
        echo "$child"
        list_descendants "$child"
    done
}

killed=0
for pid in $(list_descendants "$pane_pid"); do
    cmd="$(ps -o args= -p "$pid" 2>/dev/null)"
    case "$cmd" in
        *"gh copilot"*|*"github-copilot-cli"*|*/copilot|*"copilot-cli"*|\
        *"claude "*|*/claude|"claude"|*"claude-code"*|*"@anthropic-ai/claude-code"*)
            kill -TERM "$pid" 2>/dev/null && killed=$((killed + 1))
            ;;
    esac
done

if [ "$killed" -gt 0 ]; then
    tmux display-message "kill-ai: sent SIGTERM to $killed process(es) in $target"
    # Refresh so the marker clears promptly.
    "$(dirname "$0")/detect.sh" >/dev/null 2>&1 &
else
    tmux display-message "kill-ai: no AI process found in $target"
fi
