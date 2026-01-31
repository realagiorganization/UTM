#!/usr/bin/env bash
set -euo pipefail

session="opencode_demo"
script="$(dirname "$0")/opencode_mock_request.py"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is required but not installed" >&2
  exit 1
fi

if tmux has-session -t "$session" 2>/dev/null; then
  tmux kill-session -t "$session"
fi

tmux new-session -d -s "$session" "${script}; tmux wait-for -S ${session}_done"

tmux wait-for "${session}_done"

# Capture output from the tmux pane to show in the recording/logs.
tmux capture-pane -pt "$session"

tmux kill-session -t "$session"
