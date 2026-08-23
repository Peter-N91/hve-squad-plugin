#!/usr/bin/env bash
# preToolUse (matcher: task) — three best-effort dispatch-time checks in one script.
# Sources: squad-intake-gate.instructions.md, squad-routing.instructions.md (Tracker-Write Gate),
# squad-federation.instructions.md (naming + no-overwrite). See ../README.md for scope/limitations.
set -uo pipefail

input="$(cat)"
decisions_file=".copilot-tracking/squad/decisions.md"

# --- Check 1: Intake Readiness Verdict gate ---
# Best-effort: only checks the default single-squad decisions.md path (not a federation member's).
if [ -f "$decisions_file" ] && printf '%s' "$input" | grep -Eiq 'plan|implement|developer|lead'; then
  last_verdict_block="$(grep -n 'Intake Readiness Verdict' "$decisions_file" | tail -1 | cut -d: -f1)"
  if [ -n "$last_verdict_block" ]; then
    verdict_line="$(tail -n +"$last_verdict_block" "$decisions_file" | grep -m1 -Ei 'Verdict:')"
    if printf '%s' "$verdict_line" | grep -Eiq 'Not-Ready'; then
      printf '%s\n' '{"permissionDecision":"deny","permissionDecisionReason":"Intake Gate (squad-intake-gate.instructions.md): the latest recorded Intake Readiness Verdict in decisions.md is Not-Ready. Dispatching a plan/implement stage is denied until the verdict is re-run and reaches Ready or Ready-With-Gaps."}'
      exit 0
    fi
  fi
fi

# --- Check 2: Tracker-Write Gate ---
if printf '%s' "$input" | grep -Eiq '(work item|backlog|jira issue).*(create|push|apply|sync)|(create|push|apply|sync).*(work item|backlog|jira issue)'; then
  if ! printf '%s' "$input" | grep -Fq 'Squad Backlog Executor'; then
    printf '%s\n' '{"permissionDecision":"deny","permissionDecisionReason":"Tracker-Write Gate (squad-routing.instructions.md): only Squad Backlog Executor may perform a tracker write (ADO/Jira work-item create or update). Dispatch that role instead, with a single recorded approval per batch."}'
    exit 0
  fi
fi

# --- Check 3: Federation sub-squad naming guard ---
name_match="$(printf '%s' "$input" | grep -Eo 'members/[A-Za-z0-9_-]+' | head -1 | sed -E 's#members/##')"
if [ -n "$name_match" ]; then
  if ! printf '%s' "$name_match" | grep -Eq '^[a-z0-9][a-z0-9-]*$'; then
    printf '%s\n' '{"permissionDecision":"deny","permissionDecisionReason":"squad-federation.instructions.md naming rule: sub-squad name '"$name_match"' fails ^[a-z0-9][a-z0-9-]*$. Choose a lower-kebab-case name before creating members/'"$name_match"'/."}'
    exit 0
  fi
fi

printf '%s\n' '{"permissionDecision":"allow"}'
