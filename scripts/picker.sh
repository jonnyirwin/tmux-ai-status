#!/usr/bin/env bash
# Open a choose-tree picker filtered to sessions/windows/panes with an AI assistant.
# Records the current pane as @ai_prev_pane so `last.sh` can jump back.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$CURRENT_DIR/detect.sh" >/dev/null 2>&1 &

target="${TMUX_PANE:-$(tmux display-message -p '#{pane_id}')}"
icon="$(tmux show-option -gv '@ai_icon')"
current="$(tmux display-message -t "$target" -p '#{session_name}:#{window_index}.#{pane_index}')"
tmux set-option -g "@ai_prev_pane" "$current"

# Filter: non-empty = shown. Each scope uses its own option so nothing is inherited.
filter='#{?pane_format,#{@ai_pane_tool},#{?window_format,#{@ai_window_tool},#{@ai_session_tool}}}'

format="#{?pane_format,\
#{?@ai_pane_tool,${icon} #{@ai_pane_tool}#{?@ai_pane_active, •,}  — ,  }#{pane_current_command} \"#{pane_title}\",\
#{?window_format,\
#{?@ai_window_tool,${icon} ,}#{window_index}: #{window_name}#{window_flags} (#{window_panes}p),\
#{?@ai_session_tool,${icon} ,}#{session_name}: #{session_windows} windows#{?session_attached, (attached),}}}"

tmux choose-tree -t "$target" -Zw -f "$filter" -F "$format"
