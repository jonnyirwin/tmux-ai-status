#!/usr/bin/env bash
# choose-tree picker filtered to AI panes; Enter runs kill-ai on the selection.
# choose-tree renders a live preview of the highlighted pane, so the user can see
# the claude/copilot UI before deciding what to kill.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$CURRENT_DIR/detect.sh" >/dev/null 2>&1 &

icon="$(tmux show-option -gv '@ai_icon')"

filter='#{?pane_format,#{@ai_pane_tool},#{?window_format,#{@ai_window_tool},#{@ai_session_tool}}}'

format="#{?pane_format,\
#{?@ai_pane_tool,${icon} #{@ai_pane_tool} — ,  }#{pane_current_command} \"#{pane_title}\",\
#{?window_format,\
#{?@ai_window_tool,${icon} ,}#{window_index}: #{window_name}#{window_flags} (#{window_panes}p),\
#{?@ai_session_tool,${icon} ,}#{session_name}: #{session_windows} windows#{?session_attached, (attached),}}}"

# %% expands to the selected target (session:window.pane or similar).
# run-shell runs our kill-ai script against it.
tmux choose-tree -Zw -f "$filter" -F "$format" \
    "run-shell \"$CURRENT_DIR/kill-ai.sh '%%'\""
