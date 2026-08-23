# preToolUse (matcher: task) — three best-effort dispatch-time checks in one script.
# Sources: squad-intake-gate.instructions.md, squad-routing.instructions.md (Tracker-Write Gate),
# squad-federation.instructions.md (naming + no-overwrite). See ../README.md for scope/limitations.
$ErrorActionPreference = 'SilentlyContinue'

$input_raw = [Console]::In.ReadToEnd()
$decisionsFile = '.copilot-tracking/squad/decisions.md'

# --- Check 1: Intake Readiness Verdict gate ---
if ((Test-Path -LiteralPath $decisionsFile -PathType Leaf) -and ($input_raw -match '(?i)plan|implement|developer|lead')) {
    $lines = Get-Content -LiteralPath $decisionsFile
    $lastVerdictIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match 'Intake Readiness Verdict') { $lastVerdictIdx = $i }
    }
    if ($lastVerdictIdx -ge 0) {
        $verdictLine = ($lines[$lastVerdictIdx..($lines.Count - 1)] | Where-Object { $_ -match '(?i)Verdict:' } | Select-Object -First 1)
        if ($verdictLine -match '(?i)Not-Ready') {
            $reason = 'Intake Gate (squad-intake-gate.instructions.md): the latest recorded Intake Readiness Verdict in decisions.md is Not-Ready. Dispatching a plan/implement stage is denied until the verdict is re-run and reaches Ready or Ready-With-Gaps.'
            (@{ permissionDecision = 'deny'; permissionDecisionReason = $reason } | ConvertTo-Json -Compress) | Write-Output
            exit 0
        }
    }
}

# --- Check 2: Tracker-Write Gate ---
if ($input_raw -match '(?i)(work item|backlog|jira issue).*(create|push|apply|sync)|(create|push|apply|sync).*(work item|backlog|jira issue)') {
    if ($input_raw -notmatch 'Squad Backlog Executor') {
        $reason = 'Tracker-Write Gate (squad-routing.instructions.md): only Squad Backlog Executor may perform a tracker write (ADO/Jira work-item create or update). Dispatch that role instead, with a single recorded approval per batch.'
        (@{ permissionDecision = 'deny'; permissionDecisionReason = $reason } | ConvertTo-Json -Compress) | Write-Output
        exit 0
    }
}

# --- Check 3: Federation sub-squad naming guard ---
$nameMatch = [regex]::Match($input_raw, 'members/([A-Za-z0-9_-]+)')
if ($nameMatch.Success) {
    $name = $nameMatch.Groups[1].Value
    if ($name -notmatch '^[a-z0-9][a-z0-9-]*$') {
        $reason = "squad-federation.instructions.md naming rule: sub-squad name $name fails ^[a-z0-9][a-z0-9-]*`$. Choose a lower-kebab-case name before creating members/$name/."
        (@{ permissionDecision = 'deny'; permissionDecisionReason = $reason } | ConvertTo-Json -Compress) | Write-Output
        exit 0
    }
}

Write-Output '{"permissionDecision":"allow"}'
