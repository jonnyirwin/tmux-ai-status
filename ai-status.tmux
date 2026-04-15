#!/usr/bin/env bash
# tmux-ai — mark and navigate tmux panes running AI assistants.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$CURRENT_DIR/scripts"

# User-configurable options (can be overridden in .tmux.conf).
default_key="a"
default_kill_key="X"
default_cycle_key="A"
default_last_key="B"
default_killall_key="K"
default_icon="󰚩"
default_active_color="magenta"
default_idle_color="brightblack"
default_refresh_interval="5"

get_tmux_option() {
    local option="$1" default="$2"
    local value
    value="$(tmux show-option -gqv "$option")"
    [ -n "$value" ] && echo "$value" || echo "$default"
}

key="$(get_tmux_option "@ai_key" "$default_key")"
kill_key="$(get_tmux_option "@ai_kill_key" "$default_kill_key")"
cycle_key="$(get_tmux_option "@ai_cycle_key" "$default_cycle_key")"
last_key="$(get_tmux_option "@ai_last_key" "$default_last_key")"
killall_key="$(get_tmux_option "@ai_killall_key" "$default_killall_key")"
icon="$(get_tmux_option "@ai_icon" "$default_icon")"
active_color="$(get_tmux_option "@ai_active_color" "$default_active_color")"
idle_color="$(get_tmux_option "@ai_idle_color" "$default_idle_color")"
interval="$(get_tmux_option "@ai_refresh_interval" "$default_refresh_interval")"

tmux set-option -g "@ai_icon" "$icon"
tmux set-option -g "@ai_active_color" "$active_color"
tmux set-option -g "@ai_idle_color" "$idle_color"

# Keybindings.
tmux bind-key "$key"         run-shell "$SCRIPTS_DIR/picker.sh"
tmux bind-key "$kill_key"    run-shell "$SCRIPTS_DIR/kill-picker.sh"
tmux bind-key "$cycle_key"   run-shell "$SCRIPTS_DIR/cycle.sh"
tmux bind-key "$last_key"    run-shell "$SCRIPTS_DIR/last.sh"
tmux bind-key "$killall_key" confirm-before -p "Kill all AI processes? (y/n)" "run-shell '$SCRIPTS_DIR/kill-all.sh'"

# Manual refresh.
tmux bind-key "R" run-shell "$SCRIPTS_DIR/detect.sh"

# Hooks — rescan on structural changes.
for hook in after-new-window after-new-session after-split-window \
            after-kill-pane pane-exited window-linked window-unlinked \
            client-attached; do
    tmux set-hook -g "$hook" "run-shell -b '$SCRIPTS_DIR/detect.sh'"
done

# Periodic refresh via background daemon.
tmux set-option -g "@ai_refresh_interval" "$interval"
"$SCRIPTS_DIR/daemon.sh" start >/dev/null 2>&1 &

# Visual markers — prepend icon to window status and pane border title when AI present.
# Idempotent: checks for the sentinel so re-sourcing doesn't nest markers,
# and re-applies via hooks in case other plugins (TPM, themes) overwrite formats.
"$SCRIPTS_DIR/apply-markers.sh"

tmux set-hook -g client-attached "run-shell -b '$SCRIPTS_DIR/apply-markers.sh'"

# Initial scan.
"$SCRIPTS_DIR/detect.sh"
