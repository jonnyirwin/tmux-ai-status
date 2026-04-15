#!/usr/bin/env bash
# Jump to the next AI pane in a stable order. Records the current pane in
# @ai_prev_pane so `last.sh` can swap back.

set -u

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$CURRENT_DIR/detect.sh"

current="$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}')"

mapfile -t panes < <(tmux list-panes -a \
    -F '#{?@ai_pane_tool,#{session_name}:#{window_index}.#{pane_index},}' \
    | grep -v '^$')

count="${#panes[@]}"
if [ "$count" -eq 0 ]; then
    tmux display-message "tmux-ai: no AI panes"
    exit 0
fi

# Find current pane in the list; jump to the next one (wrap around).
target=""
for i in "${!panes[@]}"; do
    if [ "${panes[$i]}" = "$current" ]; then
        target="${panes[$(( (i + 1) % count ))]}"
        break
    fi
done
[ -z "$target" ] && target="${panes[0]}"

tmux set-option -g "@ai_prev_pane" "$current"
tmux switch-client -t "$target"
tmux select-pane -t "$target"
