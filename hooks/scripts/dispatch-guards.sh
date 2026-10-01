#!/usr/bin/env bash
# preToolUse (matcher: task) — four best-effort dispatch-time checks in one script.
# Sources: squad-intake-gate.instructions.md, squad-routing.instructions.md (Tracker-Write Gate),
# squad-federation.instructions.md (naming + no-overwrite), model-routing.md (routed model). See ../README.md for scope/limitations.
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
# The Squad Scribe writes only squad state, never a tracker; a Scribe dispatch is exempt by agent name.
# A write verb must sit next to a tracker noun in the same sentence; negated phrasing does not count,
# and a bare "backlog" (a local planning deliverable) is not a tracker.
tracker_noun='(work items?|jira( (issues?|tickets?))?|github issues?|azure devops|ado|issue tracker|backlog handoff)'
write_verb='(create|push|apply|sync)'
tracker_write_hits="$(printf '%s' "$input" \
  | grep -Eio "[^.;]{0,40}\b${write_verb}\b[^.;]{0,40}\b${tracker_noun}\b|[^.;]{0,40}\b${tracker_noun}\b[^.;]{0,15}\b${write_verb}\b" \
  | grep -Eiv "(\bnot|\bnever|\bwithout|n't)[[:space:]]+([[:alnum:]_]+[[:space:]]+){0,2}${write_verb}\b")"
if ! printf '%s' "$input" | grep -Eiq '(agent_type|agentName)\\?"[[:space:]]*:[[:space:]]*\\?"Squad Scribe\\?"' \
  && [ -n "$tracker_write_hits" ]; then
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

# --- Check 4: Routed-model guard ---
# model-routing.md Precedence: under `Model routing: ranked` or `manual`, a dispatch to a roster agent
# passes that row's `Model` cell. Compares only; never fills or changes the cell. Squad Scribe is exempt.
json_field() {
  # Reads a string field from toolArgs whether it arrives as an object or a JSON-encoded string.
  printf '%s' "$input" | grep -Eo '\\?"'"$1"'\\?"[[:space:]]*:[[:space:]]*\\?"[^"\\]*' | head -1 | sed -E 's/.*:[[:space:]]*\\?"//'
}
agent_type="$(json_field agent_type)"
[ -z "$agent_type" ] && agent_type="$(json_field agentName)"
requested_model="$(json_field model)"
if [ -n "$agent_type" ] && [ "$agent_type" != "Squad Scribe" ]; then
  team_file=".copilot-tracking/squad/team.md"
  member="$(printf '%s' "$input" | grep -Eo 'members[\\/]+[a-z0-9][a-z0-9-]*' | head -1 | sed -E 's#members[\\/]+##')"
  if [ -n "$member" ] && [ -f ".copilot-tracking/squad/members/$member/team.md" ]; then
    team_file=".copilot-tracking/squad/members/$member/team.md"
  fi
  if [ -f "$team_file" ] && grep -Eq '^[[:space:]]*Model routing:[[:space:]]*(ranked|manual)\b' "$team_file"; then
    allowed="$(awk -v agent="$agent_type" '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      !/^[ \t]*\|/ { mi = 0; next }
      {
        line = $0; sub(/^[ \t]*\|/, "", line); sub(/\|[ \t]*$/, "", line)
        n = split(line, c, "|"); for (i = 1; i <= n; i++) c[i] = trim(c[i])
        if (!mi) { for (i = 1; i <= n; i++) { if (c[i] == "Model") mi = i; if (c[i] == "Agent Name (Primary)") pi = i; if (c[i] == "Alternate Agents") ai = i }
                   if (!(mi && pi)) mi = 0; next }
        if (c[1] ~ /^-+$/) next
        m = c[mi]; gsub(/`/, "", m); m = trim(m)
        if (m == "" || m == "—" || m == "-") next
        hit = (c[pi] == agent)
        if (ai) { k = split(c[ai], alts, ","); for (j = 1; j <= k; j++) if (trim(alts[j]) == agent) hit = 1 }
        if (hit && !(m in seen)) { seen[m] = 1; out = out (out == "" ? "" : " or ") m }
      }
      END { print out }' "$team_file")"
    if [ -n "$allowed" ]; then
      ok=0
      for m in $(printf '%s' "$allowed" | sed 's/ or / /g'); do [ "$m" = "$requested_model" ] && ok=1; done
      if [ "$ok" -eq 0 ]; then
        first="${allowed%% or *}"
        passed="no model"; [ -n "$requested_model" ] && passed="model '$requested_model'"
        printf '%s\n' "{\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Routed-model guard (model-routing.md Precedence): $team_file routes $agent_type to $allowed and this dispatch passed $passed. Re-dispatch with model: $first, copied from the Model cell.\"}"
        exit 0
      fi
    fi
  fi
fi

printf '%s\n' '{"permissionDecision":"allow"}'
