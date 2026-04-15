#!/usr/bin/env bash
# Scan every pane; tag panes/windows/sessions running Claude Code or GitHub Copilot CLI.
# Uses distinct option names per scope to avoid tmux's pane→window→session option inheritance.
# Also hashes visible pane content to mark AI panes as active (changing) or idle (static),
# and exports a global @ai_total count.

set -u

list_descendants() {
    local parent="$1"
    local child
    for child in $(ps -o pid= --ppid "$parent" 2>/dev/null); do
        echo "$child"
        list_descendants "$child"
    done
}

detect_tool_for_pid() {
    local root="$1"
    local pid cmd
    for pid in "$root" $(list_descendants "$root"); do
        cmd="$(ps -o args= -p "$pid" 2>/dev/null)"
        case "$cmd" in
            *"gh copilot"*|*"github-copilot-cli"*|*/copilot|*"copilot-cli"*)
                echo "copilot"; return 0;;
            *"claude "*|*/claude|"claude"|*"claude-code"*|*"@anthropic-ai/claude-code"*)
                echo "claude"; return 0;;
        esac
    done
    return 1
}

declare -A window_tool
declare -A window_active
declare -A session_tool
total=0

while IFS='|' read -r session window pane pid; do
    target="${session}:${window}.${pane}"
    if tool="$(detect_tool_for_pid "$pid")"; then
        tmux set-option -p -t "$target" "@ai_pane_tool" "$tool" 2>/dev/null
        window_tool["${session}:${window}"]="$tool"
        session_tool["${session}"]="$tool"
        total=$((total + 1))

        # Idle detection: hash visible pane, compare with previous.
        new_hash="$(tmux capture-pane -p -t "$target" 2>/dev/null | sha1sum | cut -c1-16)"
        old_hash="$(tmux show-option -pqv -t "$target" '@ai_pane_hash')"
        if [ -z "$old_hash" ] || [ "$old_hash" != "$new_hash" ]; then
            tmux set-option -p -t "$target" "@ai_pane_active" "1" 2>/dev/null
            window_active["${session}:${window}"]="1"
        else
            tmux set-option -p -u -t "$target" "@ai_pane_active" 2>/dev/null
        fi
        tmux set-option -p -t "$target" "@ai_pane_hash" "$new_hash" 2>/dev/null
    else
        tmux set-option -p -u -t "$target" "@ai_pane_tool" 2>/dev/null
        tmux set-option -p -u -t "$target" "@ai_pane_active" 2>/dev/null
        tmux set-option -p -u -t "$target" "@ai_pane_hash" 2>/dev/null
    fi
done < <(tmux list-panes -a -F '#{session_name}|#{window_index}|#{pane_index}|#{pane_pid}')

while IFS='|' read -r session window; do
    target="${session}:${window}"
    if [ -n "${window_tool[$target]:-}" ]; then
        tmux set-option -w -t "$target" "@ai_window_tool" "${window_tool[$target]}" 2>/dev/null
        if [ -n "${window_active[$target]:-}" ]; then
            tmux set-option -w -t "$target" "@ai_window_active" "1" 2>/dev/null
        else
            tmux set-option -w -u -t "$target" "@ai_window_active" 2>/dev/null
        fi
    else
        tmux set-option -w -u -t "$target" "@ai_window_tool" 2>/dev/null
        tmux set-option -w -u -t "$target" "@ai_window_active" 2>/dev/null
    fi
done < <(tmux list-windows -a -F '#{session_name}|#{window_index}')

while read -r session; do
    if [ -n "${session_tool[$session]:-}" ]; then
        tmux set-option -t "$session" "@ai_session_tool" "${session_tool[$session]}" 2>/dev/null
    else
        tmux set-option -u -t "$session" "@ai_session_tool" 2>/dev/null
    fi
done < <(tmux list-sessions -F '#{session_name}')

tmux set-option -g "@ai_total" "$total" 2>/dev/null

# Re-apply marker formats in case another plugin/theme overwrote them.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/apply-markers.sh" 2>/dev/null

# Force status-line redraw so updated counts/markers appear immediately.
tmux refresh-client -S 2>/dev/null
