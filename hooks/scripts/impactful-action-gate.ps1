# preToolUse (matcher: bash|powershell) — Impactful-Action Gate backstop.
# Source: squad-autopilot.instructions.md (Impactful-Action Gate), squad-watch-mode.instructions.md
# (the absolute unattended variant). See ../README.md for exact scope and limitations.
$ErrorActionPreference = 'SilentlyContinue'

$input_raw = [Console]::In.ReadToEnd()

$pattern = 'git\s+push|terraform\s+apply|az\s+[a-zA-Z-]+\s+(create|delete)|az\s+keyvault\s+secret|gh\s+pr\s+merge|kubectl\s+(apply|delete)|npm\s+publish|helm\s+(install|upgrade|uninstall)|rm\s+-rf|Remove-Item.*-Recurse.*-Force|DROP\s+TABLE|DROP\s+DATABASE'

if ($input_raw -match $pattern) {
    $reason = 'Impactful-Action Gate (squad-autopilot.instructions.md): this command matches a deploy, force-push/push, PR merge, schema migration, secret rotation, or destructive infrastructure/data operation. It requires explicit human confirmation before it may run. If this is a false positive, ask the human to confirm and re-run manually rather than retrying automatically.'
    $out = @{ permissionDecision = 'deny'; permissionDecisionReason = $reason } | ConvertTo-Json -Compress
    Write-Output $out
} else {
    Write-Output '{"permissionDecision":"allow"}'
}
