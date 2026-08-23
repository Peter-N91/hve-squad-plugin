#!/usr/bin/env bash
# preToolUse (matcher: create|edit) — squad-floor/squad-state append-only guard.
# Source: squad-floor.instructions.md, squad-state.instructions.md.
# See ../README.md "Known limitation" column: this hook cannot verify caller identity
# (the single-writer/Scribe-only half of the rule), and it only catches a full overwrite
# via the `create` tool, not a non-append `edit`.
set -uo pipefail

input="$(cat)"

tool_name="$(printf '%s' "$input" | grep -Eo '"tool_?[Nn]ame"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed -E 's/.*:"([^"]+)"$/\1/')"

append_only_regex='[^"]*\.copilot-tracking/squad/[^"]*(decisions\.md|notifications\.md|federation\.md|history/[^"]*\.md)'

if [ "$tool_name" = "create" ]; then
  path_match="$(printf '%s' "$input" | grep -Eo "$append_only_regex" | head -1)"
  if [ -n "$path_match" ] && [ -f "$path_match" ]; then
    printf '%s\n' '{"permissionDecision":"deny","permissionDecisionReason":"squad-state append-only guard: '"$path_match"' already exists and is an append-only squad-state file (decisions.md, notifications.md, federation.md, or a history/*.md file). A full overwrite via the create tool is denied; append to the end of the file instead. Note: this hook cannot verify the calling agent is the Squad Scribe (preToolUse payloads carry no caller identity)."}'
    exit 0
  fi
fi

printf '%s\n' '{"permissionDecision":"allow"}'
