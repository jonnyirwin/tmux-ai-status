#!/usr/bin/env bash
# Idempotently wrap window-status-format and pane-border-format with AI markers.
# Re-run on config reloads or after other plugins overwrite the formats.

set -u

icon="$(tmux show-option -gqv '@ai_icon')"
active_color="$(tmux show-option -gqv '@ai_active_color')"
idle_color="$(tmux show-option -gqv '@ai_idle_color')"

win_color="#[fg=#{?@ai_window_active,${active_color},${idle_color}}]"
pane_color="#[fg=#{?@ai_pane_active,${active_color},${idle_color}}]"
win_marker='#{?@ai_window_tool,'"${win_color}${icon}"' #[default],}'
pane_marker='#{?@ai_pane_tool, '"${pane_color}${icon}"' #{@ai_pane_tool}#[default],}'

wrap_once() {
    local opt="$1" marker="$2" position="$3"  # position: prefix|suffix
    local current
    current="$(tmux show-option -gv "$opt")"
    case "$current" in
        *"@ai_window_tool"*|*"@ai_pane_tool"*) return 0 ;;
    esac
    if [ "$position" = "prefix" ]; then
        tmux set-option -g "$opt" "${marker}${current}"
    else
        tmux set-option -g "$opt" "${current}${marker}"
    fi
}

window_marker="$(tmux show-option -gqv '@ai_window_marker')"
if [ "$window_marker" != "off" ]; then
    wrap_once window-status-format "$win_marker" prefix
    wrap_once window-status-current-format "$win_marker" prefix
fi
wrap_once pane-border-format "$pane_marker" suffix
