#!/usr/bin/env bash
# userPromptSubmitted — log-only injection-safety note.
# Source: squad-watch-mode.instructions.md (untrusted trigger payload rule).
# IMPORTANT (confirmed against the hooks reference): a command-type userPromptSubmitted
# hook's output (modifiedPrompt) is NOT honored - only SDK programmatic hooks can act on
# this event. This script has no enforcement capability; it exists only for an audit trail.
# See ../README.md.
set -uo pipefail

input="$(cat)"
log_dir=".copilot-tracking/squad"
log_file="$log_dir/hooks-audit.log"

if printf '%s' "$input" | grep -Eiq 'ignore (all )?(previous|prior) instructions|skip the (gate|approval)|disregard the (gate|rule)'; then
  if [ -d "$log_dir" ]; then
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
    printf '%s prompt contained instruction-override-shaped language (log-only; this event cannot block or rewrite for command hooks)\n' "$ts" >> "$log_file" 2>/dev/null || true
  fi
fi

printf '{}\n'
