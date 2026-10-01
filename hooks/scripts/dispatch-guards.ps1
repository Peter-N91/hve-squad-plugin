# preToolUse (matcher: task) — four best-effort dispatch-time checks in one script.
# Sources: squad-intake-gate.instructions.md, squad-routing.instructions.md (Tracker-Write Gate),
# squad-federation.instructions.md (naming + no-overwrite), model-routing.md (routed model). See ../README.md for scope/limitations.
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
# The Squad Scribe writes only squad state, never a tracker, and its payloads routinely
# quote the request ("create ... a prioritized backlog"); matching its prompt text denied
# legitimate state hand-offs, so a Scribe dispatch is exempt by agent name.
$isScribeDispatch = $input_raw -match '(?i)(agent_type|agentName)\\?"\s*:\s*\\?"Squad Scribe\\?"'
# A write verb must sit next to a tracker noun in the same sentence, and negated phrasing
# ("must not create ... in Azure DevOps") does not count. A bare "backlog" is a local planning
# deliverable, not a tracker: matching it anywhere in the prompt denied every planning role whose
# request asked for "a prioritized backlog" and broke pipelined Scribe + next-stage blocks.
$trackerNoun = '(work items?|jira( (issues?|tickets?))?|github issues?|azure devops|ado|issue tracker|backlog handoff)'
$writeVerb = '(create|push|apply|sync)'
$trackerWritePattern = "(?i)[^.;]{0,40}\b$writeVerb\b[^.;]{0,40}\b$trackerNoun\b|[^.;]{0,40}\b$trackerNoun\b[^.;]{0,15}\b$writeVerb\b"
$negatedWrite = "(?i)(\bnot|\bnever|\bwithout|n't)\s+(\w+\s+){0,2}$writeVerb\b"
$trackerWriteHits = @([regex]::Matches($input_raw, $trackerWritePattern) | Where-Object { $_.Value -notmatch $negatedWrite })
if (-not $isScribeDispatch -and $trackerWriteHits.Count -gt 0) {
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

# --- Check 4: Routed-model guard ---
# model-routing.md Precedence: under `Model routing: ranked` or `manual`, a dispatch to a roster
# agent passes that row's `Model` cell. Compares the dispatch with the cell; never fills or changes
# the cell. The Squad Scribe is exempt: its own model pin governs (model-routing.md).
$dispatchArgs = $null
try {
    $hookInput = $input_raw | ConvertFrom-Json
    $dispatchArgs = $hookInput.toolArgs
    if ($null -eq $dispatchArgs) { $dispatchArgs = $hookInput.tool_input }
    if ($dispatchArgs -is [string]) { $dispatchArgs = $dispatchArgs | ConvertFrom-Json }
}
catch { $dispatchArgs = $null }
if ($null -ne $dispatchArgs) {
    $agentType = [string]$dispatchArgs.agent_type
    if (-not $agentType) { $agentType = [string]$dispatchArgs.agentName }
    $requestedModel = [string]$dispatchArgs.model
    if ($agentType -and $agentType -ne 'Squad Scribe') {
        $teamFile = '.copilot-tracking/squad/team.md'
        $memberMatch = [regex]::Match($input_raw, 'members[\\/]+([a-z0-9][a-z0-9-]*)')
        if ($memberMatch.Success) {
            $memberTeam = ".copilot-tracking/squad/members/$($memberMatch.Groups[1].Value)/team.md"
            if (Test-Path -LiteralPath $memberTeam -PathType Leaf) { $teamFile = $memberTeam }
        }
        if (Test-Path -LiteralPath $teamFile -PathType Leaf) {
            $teamLines = Get-Content -LiteralPath $teamFile -Encoding UTF8
            if (@($teamLines | Where-Object { $_ -match '^\s*Model routing:\s*(ranked|manual)\b' }).Count -gt 0) {
                $header = $null
                $allowed = New-Object System.Collections.Generic.List[string]
                foreach ($line in $teamLines) {
                    if ($line -notmatch '^\s*\|') { $header = $null; continue }
                    $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
                    if ($null -eq $header) {
                        if ($cells -contains 'Model' -and $cells -contains 'Agent Name (Primary)') { $header = $cells }
                        continue
                    }
                    if ($cells[0] -match '^-+$') { continue }
                    $modelCell = ($cells[[array]::IndexOf($header, 'Model')] -replace '`', '').Trim()
                    if (-not $modelCell -or $modelCell -eq [string][char]0x2014 -or $modelCell -eq '-') { continue }
                    $names = New-Object System.Collections.Generic.List[string]
                    $names.Add($cells[[array]::IndexOf($header, 'Agent Name (Primary)')])
                    $altIndex = [array]::IndexOf($header, 'Alternate Agents')
                    if ($altIndex -ge 0) { foreach ($alt in $cells[$altIndex].Split(',')) { $names.Add($alt.Trim()) } }
                    if ($names -contains $agentType -and -not $allowed.Contains($modelCell)) { $allowed.Add($modelCell) }
                }
                if ($allowed.Count -gt 0 -and -not $allowed.Contains($requestedModel)) {
                    $passed = if ($requestedModel) { "model '$requestedModel'" } else { 'no model' }
                    $reason = "Routed-model guard (model-routing.md Precedence): $teamFile routes $agentType to $($allowed -join ' or ') and this dispatch passed $passed. Re-dispatch with model: $($allowed[0]), copied from the Model cell."
                    (@{ permissionDecision = 'deny'; permissionDecisionReason = $reason } | ConvertTo-Json -Compress) | Write-Output
                    exit 0
                }
            }
        }
    }
}

Write-Output '{"permissionDecision":"allow"}'
