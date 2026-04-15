# tmux-ai-status

Find and jump between tmux panes running **Claude Code** or **GitHub Copilot CLI**.

## What it does

- Scans every pane across every session; detects `claude` / `gh copilot` processes in the pane's process tree.
- Prepends a magenta icon to the window-status entry when a window contains an AI pane.
- Appends the tool name to the pane-border title for the AI pane itself.
- Shows an **active/idle** indicator: icon stays bright while the AI is producing output, dims when it's waiting.
- Exposes a total count via `#{@ai_total}` for status-line use.
- Adds bindings for picking, cycling, jumping back, and killing AI processes.
- Rescans on window/pane/session changes, plus a periodic background refresh.

## Requirements

- tmux 3.2+ (for `choose-tree -f` filtering and `-Zw` flags)
- `ps`, `sha1sum`, `bash`
- A Nerd Font if you want the default icon to render; otherwise override `@ai_icon`

## Install

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'jonnyirwin/tmux-ai-status'
```

Or manually:

```tmux
run-shell ~/path/to/tmux-ai-status/ai-status.tmux
```

Reload tmux config (`prefix + I` under TPM, or `tmux source-file ~/.tmux.conf`).

## Usage

- `prefix + a` — open AI picker (jump to a pane).
- `prefix + A` — cycle to the next AI pane (wraps).
- `prefix + B` — jump back to the pane you were in before the last picker/cycle (press again to toggle).
- `prefix + X` — open kill picker: a `choose-tree` of AI panes with a live preview; Enter terminates just the `claude` / `copilot` process.
- `prefix + K` — kill **every** AI process across the server (asks for confirmation).
- `prefix + R` — force a rescan.

Inside the picker (standard `choose-tree` keys):

- `Enter` — jump to the selected session/window/pane.
- `x` — kill the selected item (asks for confirmation). Use this to close an AI session, window, or pane.
- `t` then `X` — tag multiple items with `t`, then kill them all with `X`.
- `q` — dismiss the picker.

## Status-line counter

Append the count of AI panes to your status line:

```tmux
set -g status-right "AI: #{@ai_total} | %H:%M"
```

Wrap it so the segment only shows when something's running:

```tmux
set -g status-right "#{?@ai_total,AI: #{@ai_total} | ,}%H:%M"
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `@ai_key` | `a` | Key (after prefix) that opens the picker |
| `@ai_cycle_key` | `A` | Key that cycles to the next AI pane |
| `@ai_last_key` | `B` | Key that jumps back to the previous pane |
| `@ai_kill_key` | `X` | Key that opens the kill picker |
| `@ai_killall_key` | `K` | Key that kills every AI process (with confirm) |
| `@ai_icon` | `󰚩` | Icon shown next to AI windows/panes (needs a Nerd Font) |
| `@ai_active_color` | `magenta` | Color for the icon when the AI is producing output |
| `@ai_idle_color` | `brightblack` | Color for the icon when the AI is idle |
| `@ai_refresh_interval` | `5` | Background rescan interval in seconds |

Set in `.tmux.conf` before the plugin line, e.g. `set -g @ai_icon "*"`.

## How detection works

Each pane's `pane_pid` is walked via `ps --ppid`; if any descendant's args match `claude`, `claude-code`, `gh copilot`, `github-copilot-cli`, or `copilot-cli`, the pane is tagged. Window and session tags aggregate from their contained panes.

**Idle vs active** is derived by hashing the visible pane on every scan; if the hash changes between ticks the pane is flagged active, otherwise idle. Claude/Copilot spinners and streaming output keep the hash changing; a pane waiting for input goes static.

Options written:

- `@ai_pane_tool` (pane scope) — tool name, or unset
- `@ai_pane_active` (pane scope) — `1` if producing output, unset if idle
- `@ai_pane_hash` (pane scope) — internal, last content hash
- `@ai_window_tool` / `@ai_window_active` (window scope) — aggregated from panes
- `@ai_session_tool` (session scope) — aggregated from windows
- `@ai_total` (global) — count of AI panes server-wide
- `@ai_prev_pane` (global) — last pane jumped from, for `prefix + B`

Separate scopes sidestep tmux's option inheritance (pane → window → session), so sibling panes don't inherit an AI tag from their window.
