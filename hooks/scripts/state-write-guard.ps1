# preToolUse (matcher: create|edit) — squad-floor/squad-state append-only guard.
# Source: squad-floor.instructions.md, squad-state.instructions.md.
# See ../README.md "Known limitation" column: this hook cannot verify caller identity
# (the single-writer/Scribe-only half of the rule), and it only catches a full overwrite
# via the `create` tool, not a non-append `edit`.
$ErrorActionPreference = 'SilentlyContinue'

$input_raw = [Console]::In.ReadToEnd()

$toolNameMatch = [regex]::Match($input_raw, '"tool_?[Nn]ame"\s*:\s*"([^"]+)"')
$toolName = if ($toolNameMatch.Success) { $toolNameMatch.Groups[1].Value } else { '' }

$appendOnlyRegex = '[^"]*\.copilot-tracking/squad/[^"]*(decisions\.md|notifications\.md|federation\.md|history/[^"]*\.md)'

if ($toolName -eq 'create') {
    $pathMatch = [regex]::Match($input_raw, $appendOnlyRegex)
    if ($pathMatch.Success -and (Test-Path -LiteralPath $pathMatch.Value -PathType Leaf)) {
        $reason = "squad-state append-only guard: $($pathMatch.Value) already exists and is an append-only squad-state file (decisions.md, notifications.md, federation.md, or a history/*.md file). A full overwrite via the create tool is denied; append to the end of the file instead. Note: this hook cannot verify the calling agent is the Squad Scribe (preToolUse payloads carry no caller identity)."
        $out = @{ permissionDecision = 'deny'; permissionDecisionReason = $reason } | ConvertTo-Json -Compress
        Write-Output $out
        exit 0
    }
}

Write-Output '{"permissionDecision":"allow"}'
