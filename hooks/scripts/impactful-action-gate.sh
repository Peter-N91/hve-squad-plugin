#!/usr/bin/env bash
# preToolUse (matcher: bash|powershell) — Impactful-Action Gate backstop.
# Source: squad-autopilot.instructions.md (Impactful-Action Gate), squad-watch-mode.instructions.md
# (the absolute unattended variant). See ../README.md for exact scope and limitations.
set -uo pipefail

input="$(cat)"

pattern='git[[:space:]]+push|terraform[[:space:]]+apply|az[[:space:]]+[a-zA-Z-]+[[:space:]]+(create|delete)|az[[:space:]]+keyvault[[:space:]]+secret|gh[[:space:]]+pr[[:space:]]+merge|kubectl[[:space:]]+(apply|delete)|npm[[:space:]]+publish|helm[[:space:]]+(install|upgrade|uninstall)|rm[[:space:]]+-rf|DROP[[:space:]]+TABLE|DROP[[:space:]]+DATABASE'

if printf '%s' "$input" | grep -Eiq "$pattern"; then
  printf '%s\n' '{"permissionDecision":"deny","permissionDecisionReason":"Impactful-Action Gate (squad-autopilot.instructions.md): this command matches a deploy, force-push/push, PR merge, schema migration, secret rotation, or destructive infrastructure/data operation. It requires explicit human confirmation before it may run. If this is a false positive, ask the human to confirm and re-run manually rather than retrying automatically."}'
else
  printf '%s\n' '{"permissionDecision":"allow"}'
fi
