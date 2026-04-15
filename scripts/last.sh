#!/usr/bin/env bash
# Jump back to the pane we were in before the last picker/cycle jump.
# Swaps @ai_prev_pane with the current pane so pressing again toggles.

set -u

prev="$(tmux show-option -gqv '@ai_prev_pane')"
if [ -z "$prev" ]; then
    tmux display-message "tmux-ai: no previous pane recorded"
    exit 0
fi

current="$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}')"
tmux set-option -g "@ai_prev_pane" "$current"
tmux switch-client -t "$prev" 2>/dev/null
tmux select-pane -t "$prev" 2>/dev/null
